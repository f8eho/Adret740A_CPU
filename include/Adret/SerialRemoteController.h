#pragma once

#include <stdint.h>

#include "Adret/CalibrationStore.h"
#include "Adret/FrontPanel.h"
#include "Adret/SerialCommandParser.h"

namespace adret {

class SerialRemoteController final {
public:
    SerialRemoteController() = default;
    SerialRemoteController(const SerialRemoteController&) = delete;
    SerialRemoteController& operator=(const SerialRemoteController&) = delete;

    void begin();
    void poll();
    bool handlePanelKey(front_panel::Key key);
    bool localControlsEnabled() const;
    bool calibrationActive() const;

private:
    void processRecord(const serial_protocol::FrameResult& frame);
    bool processCalibrationRecord(const serial_protocol::FrameResult& frame);
    void abortCalibration(bool reportToSerial);
    void printCalibrationPoint(const char* prefix,
                               const calibration::CalibrationPoint& point,
                               int16_t extraTenthsDb = 0);
    void commit(const serial_protocol::Transaction& transaction);
    void clearStaged();
    void sendOk();
    void sendError(serial_protocol::ErrorCode error,
                   int8_t memoryIndex = -1);
    void sendStatus();
    void sendInstrumentBusStatus();
    void sendBuildInfo();
    uint8_t statusByte() const;
    void setRemoteIndicator();

    static bool loadMemory(void* context,
                           uint8_t index,
                           control::OutputConfiguration* configuration);

    serial_protocol::MessageFramer framer_ = {};
    bool stagedValid_ = false;
    serial_protocol::Transaction staged_ = {};
    serial_protocol::RemoteState remoteState_ = {false, false};
    bool serviceRequest_ = false;
    bool errorLatched_ = false;
    serial_protocol::ErrorCode lastError_ = serial_protocol::ErrorCode::E00;
    control::OutputConfiguration calibrationInitialOutput_ = {};
    bool calibrationActive_ = false;
};

extern SerialRemoteController serialRemoteController;

}  // namespace adret
