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
    
    double CalculatePositionSize(ENUM_ORDER_TYPE orderType, double entryPrice, double slPrice)
    {
        double riskAmount = m_preferredRisk;
        
        if(riskAmount <= 0) 
        {
            Print("Error: Preferred Risk must be greater than 0");
            return 0;
        }
        
        // Calculate risk in points
        double riskPoints;
        if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY)
        {
            riskPoints = MathAbs(entryPrice - slPrice) / _Point;
        }
        else
        {
            riskPoints = MathAbs(slPrice - entryPrice) / _Point;
        }
        
        if(riskPoints == 0)
        {
            Print("Error: Risk in points is zero");
            return 0;
        }
        
        // Calculate point value
        double pointValue = CalculatePointValue(orderType, entryPrice);
        
        if(pointValue <= 0)
        {
            Print("Error: Cannot calculate point value");
            return 0;
        }
        
        // Calculate position size
        double riskPerLot = riskPoints * pointValue;
        double lots = riskAmount / riskPerLot;
        
        // Normalize lots
        return NormalizeLots(lots);
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
        double profit;
        double point = _Point;
        
        // Try to calculate profit for 1 lot with 1 point movement
        if(OrderCalcProfit(orderType, Symbol(), 1.0, price, price + point, profit))
        {
            return MathAbs(profit);
        }
        
        // Fallback calculation
        string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
        string symbol = Symbol();
        
        // For major USD pairs
        if((StringFind(symbol, "USD") >= 0 && accountCurrency == "USD") ||
           (StringFind(symbol, "EUR") >= 0 && StringSubstr(symbol, 3) == "USD" && accountCurrency == "USD"))
        {
            return 0.0001 / point * 1.0; // Approximation for USD accounts
        }
        
        return 0.0001; // Conservative fallback
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