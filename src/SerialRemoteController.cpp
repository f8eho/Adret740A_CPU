#include "Adret/SerialRemoteController.h"

#include <Arduino.h>
#include <string.h>

#include "Adret/CalibrationEprom.h"
#include "Adret/CalibrationStore.h"
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

void skipSpaces(const char* text, uint8_t length, uint8_t* position)
{
    while (*position < length &&
           (text[*position] == ' ' || text[*position] == '\t')) {
        ++*position;
    }
}

bool matchWord(const char* text,
               uint8_t length,
               uint8_t* position,
               const char* word)
{
    skipSpaces(text, length, position);
    const uint8_t start = *position;
    for (uint8_t i = 0u; word[i] != '\0'; ++i) {
        if (*position >= length ||
            asciiUpper(text[*position]) != word[i]) {
            *position = start;
            return false;
        }
        ++*position;
    }
    if (*position < length && text[*position] != ' ' &&
        text[*position] != '\t') {
        *position = start;
        return false;
    }
    return true;
}

bool atEnd(const char* text, uint8_t length, uint8_t position)
{
    skipSpaces(text, length, &position);
    return position == length;
}

bool parseUnsigned(const char* text,
                   uint8_t length,
                   uint8_t* position,
                   uint16_t maximum,
                   uint16_t* result)
{
    skipSpaces(text, length, position);
    uint32_t value = 0u;
    bool haveDigit = false;
    while (*position < length && text[*position] >= '0' &&
           text[*position] <= '9') {
        haveDigit = true;
        value = value * 10u + uint32_t(text[*position] - '0');
        ++*position;
        if (value > maximum) {
            return false;
        }
    }
    if (!haveDigit) {
        return false;
    }
    *result = uint16_t(value);
    return true;
}

bool parseTenths(const char* text,
                 uint8_t length,
                 uint8_t* position,
                 int16_t minimum,
                 int16_t maximum,
                 int16_t* result)
{
    skipSpaces(text, length, position);
    bool negative = false;
    if (*position < length &&
        (text[*position] == '+' || text[*position] == '-')) {
        negative = text[*position] == '-';
        ++*position;
    }
    uint32_t whole = 0u;
    bool haveDigit = false;
    while (*position < length && text[*position] >= '0' &&
           text[*position] <= '9') {
        haveDigit = true;
        whole = whole * 10u + uint32_t(text[*position] - '0');
        ++*position;
        if (whole > 3276u) {
            return false;
        }
    }
    if (!haveDigit) {
        return false;
    }
    uint8_t fractional = 0u;
    if (*position < length &&
        (text[*position] == '.' || text[*position] == ',')) {
        ++*position;
        if (*position >= length || text[*position] < '0' ||
            text[*position] > '9') {
            return false;
        }
        fractional = uint8_t(text[*position] - '0');
        ++*position;
        if (*position < length && text[*position] >= '0' &&
            text[*position] <= '9') {
            return false;
        }
    }
    const int32_t magnitude = int32_t(whole * 10u + fractional);
    const int32_t signedValue = negative ? -magnitude : magnitude;
    if (signedValue < minimum || signedValue > maximum) {
        return false;
    }
    *result = int16_t(signedValue);
    return true;
}

void printTenthsDb(int16_t value)
{
    const int32_t extended = value;
    const uint32_t magnitude = uint32_t(extended < 0 ? -extended : extended);
    Serial.print(extended < 0 ? '-' : '+');
    Serial.print(magnitude / 10u);
    Serial.print('.');
    Serial.print(magnitude % 10u);
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
    calibrationActive_ = false;
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
        if (calibrationActive_) {
            abortCalibration(true);
        }
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

bool SerialRemoteController::calibrationActive() const
{
    return calibrationActive_;
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

    if (processCalibrationRecord(frame)) {
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

    if (calibrationActive_ && !transaction.remoteState.remoteEnabled) {
        abortCalibration(true);
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

bool SerialRemoteController::processCalibrationRecord(
    const serial_protocol::FrameResult& frame)
{
#if ADRET_REMOTE_SERIAL
    uint8_t position = 0u;
    if (!matchWord(frame.text, frame.length, &position, "CAL")) {
        return false;
    }
    clearStaged();

    if (atEnd(frame.text, frame.length, position)) {
        Serial.print(F("CAL ERROR COMMAND\r\n"));
        return true;
    }
    if (matchWord(frame.text, frame.length, &position, "BEGIN") &&
        atEnd(frame.text, frame.length, position)) {
        if (!remoteState_.remoteEnabled) {
            Serial.print(F("CAL ERROR REMOTE_REQUIRED\r\n"));
        } else if (calibrationActive_) {
            Serial.print(F("CAL ERROR ALREADY_ACTIVE\r\n"));
        } else {
            calibrationInitialOutput_ =
                control::operatingController.settings().output;
            if (!calibration::calibrationStore.startSession()) {
                Serial.print(F("CAL ERROR EEPROM\r\n"));
            } else {
                calibrationActive_ = true;
                Serial.print(F("CAL OK BEGIN BASE_CRC="));
                Serial.print(calibration::calibrationStore.baseCrc(), HEX);
                Serial.print(F(" GENERATION="));
                Serial.print(calibration::calibrationStore.generation());
                Serial.print(F("\r\n"));
            }
        }
        return true;
    }
    if (matchWord(frame.text, frame.length, &position, "ABORT") &&
        atEnd(frame.text, frame.length, position)) {
        if (!calibrationActive_) {
            Serial.print(F("CAL ERROR NOT_ACTIVE\r\n"));
        } else {
            abortCalibration(true);
        }
        return true;
    }
    if (matchWord(frame.text, frame.length, &position, "END") &&
        atEnd(frame.text, frame.length, position)) {
        if (!calibrationActive_) {
            Serial.print(F("CAL ERROR NOT_ACTIVE\r\n"));
        } else if (!calibration::calibrationStore.commitSession()) {
            Serial.print(F("CAL ERROR EEPROM\r\n"));
        } else {
            calibrationActive_ = false;
            control::operatingController.applyRemoteConfiguration(
                calibrationInitialOutput_);
            Serial.print(F("CAL OK END GENERATION="));
            Serial.print(calibration::calibrationStore.generation());
            Serial.print(F(" RESTORED=1\r\n"));
        }
        return true;
    }

    const bool statusCommand =
        matchWord(frame.text, frame.length, &position, "STATUS");
    if (statusCommand && atEnd(frame.text, frame.length, position)) {
        const control::OutputConfiguration& output =
            control::operatingController.settings().output;
        calibration::CalibrationPoint point = {};
        if (!calibration::calibrationStore.point(
                output.frequencyHz, output.amplitudeTenthsDbm, &point)) {
            Serial.print(F("CAL ERROR POINT\r\n"));
        } else {
            Serial.print(F("CAL STATUS ACTIVE="));
            Serial.print(calibrationActive_ ? 1 : 0);
            Serial.print(F(" BASE_CRC="));
            Serial.print(calibration::calibrationStore.baseCrc(), HEX);
            Serial.print(F(" GENERATION="));
            Serial.print(calibration::calibrationStore.generation());
            Serial.print(F(" FREQ="));
            Serial.print(output.frequencyHz);
            Serial.print(F(" SET="));
            printTenthsDb(output.amplitudeTenthsDbm);
            Serial.print(F(" RF="));
            Serial.print(output.rfOff ? 0 : 1);
            Serial.print(' ');
            printCalibrationPoint("POINT", point);
        }
        return true;
    }

    if (matchWord(frame.text, frame.length, &position, "MEAS")) {
        int16_t measured = 0;
        const control::OutputConfiguration& output =
            control::operatingController.settings().output;
        if (!calibrationActive_) {
            Serial.print(F("CAL ERROR NOT_ACTIVE\r\n"));
        } else if (output.rfOff) {
            Serial.print(F("CAL ERROR RF_OFF\r\n"));
        } else if (!parseTenths(frame.text, frame.length, &position,
                                -1500, 300, &measured) ||
                   !atEnd(frame.text, frame.length, position)) {
            Serial.print(F("CAL ERROR VALUE\r\n"));
        } else {
            const int16_t residual =
                int16_t(measured - output.amplitudeTenthsDbm);
            calibration::CalibrationPoint point = {};
            if (!calibration::calibrationStore.addWorkingCorrection(
                    output.frequencyHz, output.amplitudeTenthsDbm,
                    residual, &point)) {
                Serial.print(F("CAL ERROR CORRECTION_RANGE\r\n"));
            } else {
                control::operatingController.applyRemoteConfiguration(output);
                Serial.print(F("CAL APPLIED MEASURED="));
                printTenthsDb(measured);
                Serial.print(F(" RESIDUAL="));
                printTenthsDb(residual);
                Serial.print(' ');
                printCalibrationPoint("POINT", point);
            }
        }
        return true;
    }

    if (matchWord(frame.text, frame.length, &position, "ADJ")) {
        int16_t adjustment = 0;
        const control::OutputConfiguration& output =
            control::operatingController.settings().output;
        if (!calibrationActive_) {
            Serial.print(F("CAL ERROR NOT_ACTIVE\r\n"));
        } else if (!parseTenths(frame.text, frame.length, &position,
                                -1270, 1270, &adjustment) ||
                   !atEnd(frame.text, frame.length, position)) {
            Serial.print(F("CAL ERROR VALUE\r\n"));
        } else {
            calibration::CalibrationPoint point = {};
            if (!calibration::calibrationStore.addWorkingCorrection(
                    output.frequencyHz, output.amplitudeTenthsDbm,
                    adjustment, &point)) {
                Serial.print(F("CAL ERROR CORRECTION_RANGE\r\n"));
            } else {
                control::operatingController.applyRemoteConfiguration(output);
                Serial.print(F("CAL APPLIED ADJUSTMENT="));
                printTenthsDb(adjustment);
                Serial.print(' ');
                printCalibrationPoint("POINT", point);
            }
        }
        return true;
    }

    if (matchWord(frame.text, frame.length, &position, "CLEAR") &&
        atEnd(frame.text, frame.length, position)) {
        const control::OutputConfiguration& output =
            control::operatingController.settings().output;
        uint16_t tableIndex = 0u;
        uint16_t overlayIndex = 0u;
        uint8_t row = 0u;
        uint8_t step = 0u;
        calibration::CalibrationPoint point = {};
        if (!calibrationActive_) {
            Serial.print(F("CAL ERROR NOT_ACTIVE\r\n"));
        } else if (!calibration::correctionIndex(
                       output.frequencyHz, output.amplitudeTenthsDbm,
                       &tableIndex, &overlayIndex, &row, &step) ||
                   !calibration::calibrationStore.setWorkingOverlay(
                       row, step, 0, &point)) {
            Serial.print(F("CAL ERROR POINT\r\n"));
        } else {
            control::operatingController.applyRemoteConfiguration(output);
            Serial.print(F("CAL CLEARED "));
            printCalibrationPoint("POINT", point);
        }
        return true;
    }

    if (matchWord(frame.text, frame.length, &position, "SET")) {
        uint16_t row = 0u;
        uint16_t step = 0u;
        int16_t overlay = 0;
        calibration::CalibrationPoint point = {};
        if (!calibrationActive_) {
            Serial.print(F("CAL ERROR NOT_ACTIVE\r\n"));
        } else if (!parseUnsigned(frame.text, frame.length, &position,
                                  calibration::kStandardFrequencyRowCount - 1u,
                                  &row) ||
                   !parseUnsigned(frame.text, frame.length, &position,
                                  calibration::kAttenuatorStepCount - 1u,
                                  &step) ||
                   !parseTenths(frame.text, frame.length, &position,
                                -128, 127, &overlay) ||
                   !atEnd(frame.text, frame.length, position) ||
                   !calibration::calibrationStore.setWorkingOverlay(
                       uint8_t(row), uint8_t(step), int8_t(overlay), &point)) {
            Serial.print(F("CAL ERROR VALUE\r\n"));
        } else {
            Serial.print(F("CAL SET "));
            printCalibrationPoint("POINT", point);
        }
        return true;
    }

    if (matchWord(frame.text, frame.length, &position, "DUMP") &&
        atEnd(frame.text, frame.length, position)) {
        Serial.print(F("CAL DUMP BEGIN BASE_CRC="));
        Serial.print(calibration::calibrationStore.baseCrc(), HEX);
        Serial.print(F(" GENERATION="));
        Serial.print(calibration::calibrationStore.generation());
        Serial.print(F("\r\n"));
        for (uint8_t row = 0u;
             row < calibration::kStandardFrequencyRowCount; ++row) {
            for (uint8_t step = 0u;
                 step < calibration::kAttenuatorStepCount; ++step) {
                const uint16_t index =
                    uint16_t(row) * calibration::kAttenuatorStepCount + step;
                Serial.print(F("CAL DATA ROW="));
                Serial.print(row);
                Serial.print(F(" STEP="));
                Serial.print(step);
                Serial.print(F(" OVERLAY="));
                printTenthsDb(
                    calibration::calibrationStore.overlayByCompactIndex(index));
                Serial.print(F("\r\n"));
            }
        }
        Serial.print(F("CAL DUMP END\r\n"));
        return true;
    }

    Serial.print(F("CAL ERROR COMMAND\r\n"));
    return true;
#else
    (void)frame;
    return false;
#endif
}

void SerialRemoteController::abortCalibration(bool reportToSerial)
{
    if (!calibrationActive_) {
        return;
    }
    calibration::calibrationStore.abortSession();
    calibrationActive_ = false;
    control::operatingController.applyRemoteConfiguration(
        calibrationInitialOutput_);
#if ADRET_REMOTE_SERIAL
    if (reportToSerial) {
        Serial.print(F("CAL ABORTED RESTORED=1\r\n"));
    }
#else
    (void)reportToSerial;
#endif
}

void SerialRemoteController::printCalibrationPoint(
    const char* prefix,
    const calibration::CalibrationPoint& point,
    int16_t extraTenthsDb)
{
#if ADRET_REMOTE_SERIAL
    Serial.print(prefix);
    Serial.print(F(" ROW="));
    Serial.print(point.row);
    Serial.print(F(" STEP="));
    Serial.print(point.step);
    Serial.print(F(" INDEX="));
    Serial.print(point.tableIndex);
    Serial.print(F(" BASE="));
    printTenthsDb(point.baseTenthsDb);
    Serial.print(F(" OVERLAY="));
    printTenthsDb(point.overlayTenthsDb);
    Serial.print(F(" TOTAL="));
    printTenthsDb(point.effectiveTenthsDb);
    if (extraTenthsDb != 0) {
        Serial.print(F(" EXTRA="));
        printTenthsDb(extraTenthsDb);
    }
    Serial.print(F("\r\n"));
#else
    (void)prefix;
    (void)point;
    (void)extraTenthsDb;
#endif
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
