#pragma once

#include <stdint.h>

namespace adret {
namespace calibration {

struct CalibrationPoint {
    uint16_t tableIndex;
    uint16_t overlayIndex;
    uint8_t row;
    uint8_t step;
    int8_t baseTenthsDb;
    int8_t overlayTenthsDb;
    int8_t effectiveTenthsDb;
};

class CalibrationStore final {
public:
    CalibrationStore() = default;
    CalibrationStore(const CalibrationStore&) = delete;
    CalibrationStore& operator=(const CalibrationStore&) = delete;

    void begin();
    bool startSession();
    bool commitSession();
    void abortSession();
    bool sessionActive() const;

    bool point(uint32_t frequencyHz,
               int16_t amplitudeTenthsDbm,
               CalibrationPoint* result) const;
    bool effectiveCorrection(uint32_t frequencyHz,
                             int16_t amplitudeTenthsDbm,
                             int8_t* correctionTenthsDb) const;
    bool addWorkingCorrection(uint32_t frequencyHz,
                              int16_t amplitudeTenthsDbm,
                              int16_t addedTenthsDb,
                              CalibrationPoint* result);
    bool setWorkingOverlay(uint8_t row,
                           uint8_t step,
                           int8_t overlayTenthsDb,
                           CalibrationPoint* result = nullptr);
    int8_t overlayByCompactIndex(uint16_t overlayIndex) const;

    uint16_t baseCrc() const;
    uint16_t generation() const;

private:
    int8_t overlayFromBank(uint8_t bank, uint16_t overlayIndex) const;
    bool fillPoint(uint16_t tableIndex,
                   uint16_t overlayIndex,
                   uint8_t row,
                   uint8_t step,
                   CalibrationPoint* result) const;

    uint16_t baseCrc_ = 0u;
    uint16_t generation_ = 0u;
    uint8_t committedBank_ = 0u;
    uint8_t workingBank_ = 0u;
    bool hasCommittedBank_ = false;
    bool sessionActive_ = false;
};

extern CalibrationStore calibrationStore;

}  // namespace calibration
}  // namespace adret
