#include "Adret/SerialRemoteController.h"

#include <Arduino.h>

#include "Adret/Debug.h"
#include "Adret/InstrumentBus.h"
#include "Adret/SettingsStore.h"

namespace adret {

namespace {

constexpr uint8_t kMaximumBytesPerPoll = 32u;

void formatErrorCode(serial_protocol::ErrorCode error, char* text)
{
    const uint8_t value = uint8_t(error);
    text[0] = 'E';
    text[1] = '-';
    text[2] = char('0' + value / 10u);
    text[3] = char('0' + value % 10u);
    text[4] = '\0';
}

char asciiUpper(char value)
{
    return value >= 'a' && value <= 'z' ? char(value - ('a' - 'A')) : value;
}

bool isExactQuery(const serial_protocol::FrameResult& frame,
                  const char* mnemonic,
                  uint8_t mnemonicLength)
{
    if (frame.marker != serial_protocol::ExecutionMarker::QuestionMark) {
        return false;
    }
    uint8_t position = 0u;
    while (position < frame.length &&
           (frame.text[position] == ' ' || frame.text[position] == '\t')) {
        ++position;
    }
    for (uint8_t i = 0u; i < mnemonicLength; ++i) {
        if (position >= frame.length ||
            asciiUpper(frame.text[position++]) != mnemonic[i]) {
            return false;
        }
    }
    while (position < frame.length &&
           (frame.text[position] == ' ' || frame.text[position] == '\t')) {
        ++position;
    }
    return position == frame.length;
}

}  // namespace

SerialRemoteController serialRemoteController;

void SerialRemoteController::begin()
{
#if ADRET_REMOTE_SERIAL
    Serial.begin(115200);
    framer_.reset();
    clearStaged();
    remoteState_ = {false, false};
    serviceRequest_ = false;
    errorLatched_ = false;
    lastError_ = serial_protocol::ErrorCode::E00;
    setRemoteIndicator();
#endif
}

void SerialRemoteController::poll()
{
#if ADRET_REMOTE_SERIAL
    uint8_t processed = 0u;
    while (Serial.available() > 0 && processed < kMaximumBytesPerPoll) {
        const serial_protocol::FrameResult frame =
            framer_.consume(char(Serial.read()));
        if (frame.event != serial_protocol::FrameEvent::None) {
            processRecord(frame);
        }
        ++processed;
    }
#endif
}

bool SerialRemoteController::handlePanelKey(front_panel::Key key)
{
#if ADRET_REMOTE_SERIAL
    if (key == front_panel::Key::AddressRtl) {
        if (remoteState_.remoteEnabled && !remoteState_.localLockout) {
            remoteState_.remoteEnabled = false;
            clearStaged();
            setRemoteIndicator();
        }
        return true;
    }
    return remoteState_.remoteEnabled;
#else
    (void)key;
    return false;
#endif
}

bool SerialRemoteController::localControlsEnabled() const
{
#if ADRET_REMOTE_SERIAL
    return !remoteState_.remoteEnabled;
#else
    return true;
#endif
}

void SerialRemoteController::processRecord(
    const serial_protocol::FrameResult& frame)
{
    if (frame.event == serial_protocol::FrameEvent::Overflow) {
        clearStaged();
        sendError(serial_protocol::ErrorCode::E91);
        return;
    }
    const bool deferred = frame.event == serial_protocol::FrameEvent::Defer;
    if (frame.length == 0u) {
        if (!deferred && stagedValid_) {
            const serial_protocol::Transaction transaction = staged_;
            clearStaged();
            commit(transaction);
        }
        return;
    }

    // Read-only queries observe actual state and never consume a deferred
    // transaction.
    if (isExactQuery(frame, "STB", 3u)) {
        sendStatus();
        return;
    }
    if (isExactQuery(frame, "IB", 2u)) {
        sendInstrumentBusStatus();
        return;
    }

    const serial_protocol::ParseContext context = {
        &SerialRemoteController::loadMemory, this};
    const serial_protocol::Transaction actual =
        serial_protocol::initialTransaction(
            control::operatingController.settings().output, remoteState_);
    const serial_protocol::Transaction& base = stagedValid_ ? staged_ : actual;
    const serial_protocol::ParseResult parsed = serial_protocol::parseCommand(
        frame.text, frame.length, frame.marker, base, context);
    if (parsed.error != serial_protocol::ErrorCode::None || parsed.statusQuery) {
        clearStaged();
        sendError(parsed.error == serial_protocol::ErrorCode::None
                      ? serial_protocol::ErrorCode::E00 : parsed.error,
                  parsed.memoryErrorIndex);
        return;
    }
    if (deferred) {
        staged_ = parsed.transaction;
        stagedValid_ = true;
        sendOk();
        return;
    }
    clearStaged();
    commit(parsed.transaction);
}

void SerialRemoteController::commit(
    const serial_protocol::Transaction& transaction)
{
    if (transaction.storeMemory &&
        !settingsStore.saveMemory(transaction.storeMemoryIndex,
                                  transaction.output)) {
        sendError(serial_protocol::ErrorCode::E00,
                  int8_t(transaction.storeMemoryIndex));
        return;
    }

    const bool enteringRemote = !remoteState_.remoteEnabled &&
                                transaction.remoteState.remoteEnabled;
    if (enteringRemote) {
        control::operatingController.enterRemoteControl();
    }
    remoteState_ = transaction.remoteState;

    if (transaction.outputChanged) {
        control::operatingController.applyRemoteConfiguration(transaction.output);
    }
    if (transaction.sequenceAction == serial_protocol::SequenceAction::Define) {
        control::operatingController.defineRemoteSequence(
            transaction.sequenceStart, transaction.sequenceEnd);
    } else if (transaction.sequenceAction ==
               serial_protocol::SequenceAction::Clear) {
        control::operatingController.clearRemoteSequence();
    }
    setRemoteIndicator();

    if (transaction.hasSettingCommand) {
        errorLatched_ = false;
        lastError_ = serial_protocol::ErrorCode::E00;
        control::operatingController.clearRemoteError();
    }
    sendOk();
}

void SerialRemoteController::clearStaged()
{
    stagedValid_ = false;
    staged_ = {};
}

void SerialRemoteController::sendOk()
{
#if ADRET_REMOTE_SERIAL
    Serial.print(F("OK\r\n"));
#endif
}

void SerialRemoteController::sendError(serial_protocol::ErrorCode error,
                                       int8_t memoryIndex)
{
#if ADRET_REMOTE_SERIAL
    if (error == serial_protocol::ErrorCode::None) {
        error = serial_protocol::ErrorCode::E00;
    }
    errorLatched_ = true;
    serviceRequest_ = true;
    lastError_ = error;
    char code[5] = {};
    formatErrorCode(error, code);
    control::operatingController.showRemoteError(code, memoryIndex);
    Serial.print(F("SRQ "));
    Serial.print(statusByte());
    Serial.print(F("\r\nERR "));
    Serial.print(code);
    Serial.print(F("\r\n"));
#else
    (void)error;
    (void)memoryIndex;
#endif
}

void SerialRemoteController::sendStatus()
{
#if ADRET_REMOTE_SERIAL
    const uint8_t value = statusByte();
    Serial.print(F("STB "));
    Serial.print(value);
    Serial.print(F("\r\n"));
    serviceRequest_ = false;
#endif
}

void SerialRemoteController::sendInstrumentBusStatus()
{
#if ADRET_REMOTE_SERIAL
    using instrument_bus::instrumentBus;
    const instrument_bus::InstrumentBusTiming& timing = instrumentBus.timing();
    Serial.print(F("IB READY="));
    Serial.print(instrumentBus.ready() ? 1 : 0);
    Serial.print(F(" ERROR="));
    Serial.print(uint8_t(instrumentBus.lastError()));
    Serial.print(F(" FAULT="));
    Serial.print(uint8_t(instrumentBus.lastFault()));
    Serial.print(F(" WRITES="));
    Serial.print(timing.completedWrites);
    Serial.print(F(" FAILED="));
    Serial.print(timing.failedWrites);
    Serial.print(F(" RECOVERY_ATTEMPTS="));
    Serial.print(timing.recoveryAttempts);
    Serial.print(F(" RECOVERY_SUCCESS="));
    Serial.print(timing.successfulRecoveries);
    Serial.print(F(" LAST_US="));
    Serial.print(timing.lastWriteUs);
    Serial.print(F(" MAX_US="));
    Serial.print(timing.maximumWriteUs);
    Serial.print(F(" DATA="));
    Serial.print(instrumentBus.dataImage());
    Serial.print(F(" ADDRESS="));
    Serial.print(instrumentBus.addressImage());
    Serial.print(F("\r\n"));
#endif
}

uint8_t SerialRemoteController::statusByte() const
{
    return serial_protocol::makeStatusByte(
        remoteState_, serviceRequest_, errorLatched_, lastError_);
}

void SerialRemoteController::setRemoteIndicator()
{
    frontPanel.setIndicator(front_panel::PanelIndicator::Remote,
                            remoteState_.remoteEnabled);
}

bool SerialRemoteController::loadMemory(
    void* context,
    uint8_t index,
    control::OutputConfiguration* configuration)
{
    (void)context;
    return settingsStore.loadMemory(index, configuration);
}

}  // namespace adret
