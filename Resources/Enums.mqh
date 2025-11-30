// Project RB19 - Enumerations

// Enum for Always In mode
enum ENUM_ALWAYS_IN_MODE
{
    ALWAYS_IN_LONG,     // Always looking for long entries
    ALWAYS_IN_SHORT,    // Always looking for short entries  
    ALWAYS_IN_UNCLEAR   // Neutral - direction based on SL position
};

// Order execution results
enum ENUM_ORDER_RESULT
{
    ORDER_SUCCESS,
    ORDER_ERROR_INVALID_SL,
    ORDER_ERROR_POSITION_SIZE,
    ORDER_ERROR_EXECUTION,
    ORDER_ERROR_UNKNOWN
};

// UI States
enum ENUM_UI_STATE
{
    UI_STATE_READY,
    UI_STATE_PROCESSING,
    UI_STATE_ERROR,
    UI_STATE_MONITORING_ACTIVE
};

// Trading Directions
enum ENUM_TRADE_DIRECTION
{
    TRADE_DIRECTION_BUY,
    TRADE_DIRECTION_SELL,
    TRADE_DIRECTION_NONE
};