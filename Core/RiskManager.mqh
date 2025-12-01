// Project RB19 - Risk Management Module
#include <Trade/Trade.mqh>

class CRiskManager
{
private:
    double m_preferredRisk;
    int m_averageBarsForTP;
    
public:
    CRiskManager() : m_preferredRisk(50.0), m_averageBarsForTP(5) {}
    
    bool Initialize(double preferredRisk, int averageBars)
    {
        m_preferredRisk = preferredRisk;
        m_averageBarsForTP = averageBars;
        Print("Risk Manager initialized");
        return true;
    }
    
    bool ValidatePositionSizeParameters(ENUM_ORDER_TYPE orderType, double entryPrice, double slPrice)
    {
        if(m_preferredRisk <= 0)
        {
            Print("Error: Preferred risk must be positive");
            return false;
        }
        
        if(entryPrice <= 0 || slPrice <= 0)
        {
            Print("Error: Invalid price levels");
            return false;
        }
        
        // Check SL position relative to entry
        if((orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY) && slPrice >= entryPrice)
        {
            Print("Error: For BUY orders, SL must be below entry");
            return false;
        }
        
        if((orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL) && slPrice <= entryPrice)
        {
            Print("Error: For SELL orders, SL must be above entry");
            return false;
        }
        
        return true;
    }
    
double CalculatePositionSize(ENUM_ORDER_TYPE orderType, double entryPrice, double slPrice)
{
    double riskAmount = m_preferredRisk;
    
    // Validate inputs
    if(riskAmount <= 0 || entryPrice <= 0 || slPrice <= 0)
    {
        Print("Error: Invalid input parameters for position size calculation");
        Print("  Risk Amount: $", riskAmount);
        Print("  Entry Price: ", entryPrice);
        Print("  Stop Loss: ", slPrice);
        return 0;
    }
    
    // Calculate stop distance in points
    double stopDistancePoints;
    if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY)
    {
        stopDistancePoints = (entryPrice - slPrice) / _Point;
    }
    else if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL)
    {
        stopDistancePoints = (slPrice - entryPrice) / _Point;
    }
    else
    {
        Print("Error: Invalid order type for position size calculation");
        return 0;
    }
    
    if(stopDistancePoints <= 0)
    {
        Print("Error: Stop distance must be positive");
        Print("  Entry: ", entryPrice);
        Print("  SL: ", slPrice);
        Print("  Distance in points: ", stopDistancePoints);
        return 0;
    }
    
    // Calculate point value
    double pointValue = CalculatePointValue(orderType, entryPrice);
    
    if(pointValue <= 0)
    {
        Print("Error: Invalid point value calculated: ", pointValue);
        return 0;
    }
    
    // Calculate value at risk per lot
    double riskPerLot = stopDistancePoints * pointValue;
    
    // Debug output
    Print("Position Size Calculation:");
    Print("  Preferred Risk: $", riskAmount);
    Print("  Stop Distance: ", stopDistancePoints, " points");
    Print("  Point Value: $", pointValue);
    Print("  Risk per Lot: $", riskPerLot);
    
    if(riskPerLot <= 0)
    {
        Print("Error: Risk per lot is zero or negative");
        return 0;
    }
    
    // Calculate lots needed
    double lots = riskAmount / riskPerLot;
    
    // Normalize and validate lots
    lots = NormalizeLots(lots);
    
    Print("  Calculated Lots: ", lots);
    
    // Validate final risk
    double actualRisk = lots * riskPerLot;
    Print("  Actual Risk: $", actualRisk);
    
    // Check for significant discrepancy
    if(MathAbs(actualRisk - riskAmount) > 0.01 * riskAmount && riskAmount > 0)
    {
        Print("Warning: Actual risk ($", actualRisk, ") differs from preferred ($", riskAmount, ")");
    }
    
    return lots;
}
    
    double CalculateTakeProfitFromATR(ENUM_ORDER_TYPE orderType, double entryPrice)
    {
        double averageRange = CalculateAverageRange(m_averageBarsForTP);
        
        if(averageRange <= 0)
        {
            Print("Warning: Invalid average range calculated, using fallback");
            averageRange = FALLBACK_ATR_POINTS * _Point;
        }
        
        if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY)
        {
            return NormalizeDouble(entryPrice + averageRange, _Digits);
        }
        else if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL)
        {
            return NormalizeDouble(entryPrice - averageRange, _Digits);
        }
        
        return 0;
    }
    
    double CalculateAverageRange(int bars = 5)
    {
        if(bars <= 0) bars = 5;
        
        double totalRange = 0;
        int countedBars = 0;
        
        for(int i = 1; i <= bars; i++)
        {
            double high = iHigh(Symbol(), Period(), i);
            double low = iLow(Symbol(), Period(), i);
            
            if(high > 0 && low > 0)
            {
                totalRange += (high - low);
                countedBars++;
            }
        }
        
        if(countedBars == 0)
            return 0;
        
        return totalRange / countedBars;
    }
    
    // Getters
    double GetPreferredRisk() const { return m_preferredRisk; }
    int GetAverageBars() const { return m_averageBarsForTP; }
    
private:
    double CalculatePointValue(ENUM_ORDER_TYPE orderType, double price)
    {
        double pointValue = 0;
        
        // Get contract size
        double contractSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
        if(contractSize <= 0) contractSize = 100000; // Fallback for Forex
        
        // Calculate value per point
        double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
        
        if(tickSize > 0 && tickValue > 0)
        {
            // Correct calculation for point value
            pointValue = tickValue * (_Point / tickSize);
        }
        else
        {
            // Fallback calculation
            string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
            string baseCurrency = StringSubstr(Symbol(), 0, 3);
            string quoteCurrency = StringSubstr(Symbol(), 3, 3);
            
            // For Forex pairs where quote currency matches account currency
            if(quoteCurrency == accountCurrency)
            {
                pointValue = contractSize * _Point;
            }
            // For USD accounts with major pairs
            else if(accountCurrency == "USD")
            {
                if(quoteCurrency == "USD")
                {
                    pointValue = contractSize * _Point; // USD/XXX
                }
                else if(baseCurrency == "USD")
                {
                    // USD/XXX where XXX is not USD
                    pointValue = contractSize * _Point / price;
                }
                else
                {
                    // XXX/YYY where neither is USD
                    // Need conversion
                    string usdPair = "USD" + quoteCurrency;
                    if(SymbolInfoDouble(usdPair, SYMBOL_BID) > 0)
                    {
                        double rate = SymbolInfoDouble(usdPair, SYMBOL_BID);
                        pointValue = contractSize * _Point / rate;
                    }
                }
            }
        }
        
        // Debug output
        Print("Point Value Calculation:");
        Print("  Contract Size: ", contractSize);
        Print("  Point: ", _Point);
        Print("  Tick Size: ", tickSize);
        Print("  Tick Value: ", tickValue);
        Print("  Calculated Point Value: ", pointValue);
        
        return MathMax(pointValue, 0.000001); // Prevent division by zero
    }
    
    double NormalizeLots(double lots)
    {
        if(lots <= 0) return 0;
        
        double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
        double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
        
        // Apply step
        if(step > 0)
        {
            lots = MathFloor(lots / step) * step;
        }
        
        // Apply min/max limits
        lots = MathMax(lots, minLot);
        lots = MathMin(lots, maxLot);
        
        // Round to 2 decimal places
        return NormalizeDouble(lots, 2);
    }
};