// Project RB19 - Main Trading Engine
#include <Trade/Trade.mqh>

// Forward declarations for the missing classes
class CRiskManager;
class COrderManager;
class CControlPanel;

class CTradingEngine
{
private:
    int m_magicNumber;
    string m_tradeComment;
    int m_lastBarTime;
    
    // Module references
    CRiskManager* m_riskManager;
    COrderManager* m_orderManager;
    CControlPanel* m_controlPanel;
    
    // Current values
    double m_currentStopLossPrice;
    ENUM_ALWAYS_IN_MODE m_alwaysInMode;
    
public:
    CTradingEngine() : 
        m_magicNumber(0),
        m_lastBarTime(0),
        m_riskManager(NULL),
        m_orderManager(NULL),
        m_controlPanel(NULL),
        m_currentStopLossPrice(0.0),
        m_alwaysInMode(ALWAYS_IN_UNCLEAR)
    {}
    
    bool Initialize(int magicNumber, string comment, double stopLossPrice, ENUM_ALWAYS_IN_MODE alwaysInMode)
    {
        m_magicNumber = magicNumber;
        m_tradeComment = comment;
        m_currentStopLossPrice = stopLossPrice;
        m_alwaysInMode = alwaysInMode;
        
        Print("Trading Engine initialized");
        return true;
    }
    
    // Fixed method signatures - removed incorrect reference syntax
    // In TradingEngine.mqh - change parameter names to avoid conflicts
    void SetRiskManager(CRiskManager* riskMgr) { m_riskManager = riskMgr; }
    void SetOrderManager(COrderManager* orderMgr) { m_orderManager = orderMgr; }
    void SetControlPanel(CControlPanel* controlPanelPtr) { m_controlPanel = controlPanelPtr; }

    // Add Quick Adjust methods
    void QuickAdjustSL()
    {
        if(m_orderManager != NULL)
        {
            Print("TradingEngine: Calling OrderManager QuickAdjustStopLoss");
            m_orderManager.QuickAdjustStopLoss();
        }
        else
        {
            Print("Error: OrderManager not available for QuickAdjustSL");
        }
    }
    
    void QuickAdjustTP()
    {
        if(m_orderManager != NULL)
        {
            Print("TradingEngine: Calling OrderManager QuickAdjustTakeProfit");
            m_orderManager.QuickAdjustTakeProfit();
        }
        else
        {
            Print("Error: OrderManager not available for QuickAdjustTP");
        }
    }
 
    void OnTick()
    {
        if(m_controlPanel != NULL && m_controlPanel.IsMonitoringEnabled())
        {
            CheckForNewBar();
        }
    }
    
    void CheckForNewBar()
    {
        datetime currentBarTime = iTime(Symbol(), Period(), 0);
        
        if(currentBarTime != m_lastBarTime)
        {
            m_lastBarTime = (int)currentBarTime;
            CheckMarketOrderConditions();
        }
    }
    
    void CheckMarketOrderConditions()
    {
        double currentOpen = iOpen(Symbol(), Period(), 1);
        double currentClose = iClose(Symbol(), Period(), 1);
        double currentAsk = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double currentBid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        
        bool shouldBuy = false;
        bool shouldSell = false;
        
        switch(m_alwaysInMode)
        {
            case ALWAYS_IN_LONG:
                // Buy on bear bar or doji
                if(currentClose <= currentOpen)
                    shouldBuy = true;
                break;
                
            case ALWAYS_IN_SHORT:
                // Sell on bull bar or doji
                if(currentClose >= currentOpen)
                    shouldSell = true;
                break;
                
            case ALWAYS_IN_UNCLEAR:
                // Smart direction based on SL position
                if(m_currentStopLossPrice < currentBid && currentClose <= currentOpen)
                    shouldBuy = true;
                else if(m_currentStopLossPrice > currentAsk && currentClose >= currentOpen)
                    shouldSell = true;
                break;
        }
        
        if(shouldBuy)
        {
            Print("Market Order Condition Met: Placing BUY Market Order");
            PlaceMarketOrder(ORDER_TYPE_BUY);
        }
        else if(shouldSell)
        {
            Print("Market Order Condition Met: Placing SELL Market Order");
            PlaceMarketOrder(ORDER_TYPE_SELL);
        }
    }
    
    void PlaceLimitOrder()
    {
        if(m_riskManager == NULL || m_orderManager == NULL)
        {
            Print("Error: RiskManager or OrderManager not initialized");
            return;
        }
        
        // Get previous bar information
        double prevHigh = iHigh(Symbol(), Period(), 1);
        double prevLow = iLow(Symbol(), Period(), 1);
        
        // Determine order direction and price
        ENUM_ORDER_TYPE orderType;
        double limitPrice;
        double slPrice = NormalizeDouble(m_currentStopLossPrice, _Digits);
        
        if(slPrice < prevLow)
        {
            // Buy limit at previous bar low
            orderType = ORDER_TYPE_BUY_LIMIT;
            limitPrice = prevLow;
            Print("Setting BUY LIMIT at previous bar low: ", limitPrice);
        }
        else if(slPrice > prevHigh)
        {
            // Sell limit at previous bar high
            orderType = ORDER_TYPE_SELL_LIMIT;
            limitPrice = prevHigh;
            Print("Setting SELL LIMIT at previous bar high: ", limitPrice);
        }
        else
        {
            Print("Error: Invalid Stop Loss position.");
            Print("For BUY LIMIT: Stop Loss must be below previous bar low (", prevLow, ")");
            Print("For SELL LIMIT: Stop Loss must be above previous bar high (", prevHigh, ")");
            return;
        }
        
        // Calculate take profit from ATR
        double tpPrice = m_riskManager.CalculateTakeProfitFromATR(orderType, limitPrice);
        
        if(tpPrice <= 0)
        {
            Print("Error: Invalid Take Profit calculated");
            return;
        }
        
        // Calculate position size
        double positionSize = m_riskManager.CalculatePositionSize(orderType, limitPrice, slPrice);
        
        if(positionSize <= 0)
        {
            Print("Error: Invalid position size calculated");
            return;
        }
        
        // Display trade information
        DisplayTradeInfo(orderType, limitPrice, slPrice, tpPrice, positionSize, "LIMIT");
        
        // Place limit order using MqlTradeRequest for better compatibility
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_PENDING;
        request.symbol = Symbol();
        request.volume = positionSize;
        request.price = limitPrice;
        request.sl = slPrice;
        request.tp = tpPrice;
        request.type = orderType;
        request.magic = m_magicNumber;
        request.comment = m_tradeComment;
        request.type_filling = ORDER_FILLING_FOK;
        
        // Send order
        if(OrderSend(request, result))
        {
            Print("Limit order placed successfully!");
        }
        else
        {
            Print("Limit order placement failed. Error: ", GetLastError());
        }
    }
    
    void PlaceMarketOrder(ENUM_ORDER_TYPE orderType)
    {
        if(m_riskManager == NULL || m_orderManager == NULL)
        {
            Print("Error: RiskManager or OrderManager not initialized");
            return;
        }
        
        double entryPrice = (orderType == ORDER_TYPE_BUY) ? 
                          SymbolInfoDouble(Symbol(), SYMBOL_ASK) : 
                          SymbolInfoDouble(Symbol(), SYMBOL_BID);
        
        double slPrice = NormalizeDouble(m_currentStopLossPrice, _Digits);
        double tpPrice = m_riskManager.CalculateTakeProfitFromATR(orderType, entryPrice);
        
        // Validate SL position
        if((orderType == ORDER_TYPE_BUY && slPrice >= entryPrice) ||
           (orderType == ORDER_TYPE_SELL && slPrice <= entryPrice))
        {
            Print("Error: Invalid Stop Loss position for market order");
            return;
        }
        
        double positionSize = m_riskManager.CalculatePositionSize(orderType, entryPrice, slPrice);
        
        if(positionSize <= 0)
        {
            Print("Error: Invalid position size calculated for market order");
            return;
        }
        
        // Display trade information
        DisplayTradeInfo(orderType, entryPrice, slPrice, tpPrice, positionSize, "MARKET");
        
        CTrade* trade = m_orderManager.GetTrade();
        
        // Execute market order
        if(orderType == ORDER_TYPE_BUY)
        {
            if(trade.Buy(positionSize, Symbol(), entryPrice, slPrice, tpPrice, m_tradeComment))
            {
                Print("BUY Market Order executed successfully");
                m_orderManager.CancelNonEssentialPendingOrders();
            }
            else
            {
                Print("BUY Market Order failed. Error: ", GetLastError());
            }
        }
        else // ORDER_TYPE_SELL
        {
            if(trade.Sell(positionSize, Symbol(), entryPrice, slPrice, tpPrice, m_tradeComment))
            {
                Print("SELL Market Order executed successfully");
                m_orderManager.CancelNonEssentialPendingOrders();
            }
            else
            {
                Print("SELL Market Order failed. Error: ", GetLastError());
            }
        }
    }
    
    void PlaceImmediateMarketOrder()
    {
        if(m_riskManager == NULL || m_orderManager == NULL)
        {
            Print("Error: RiskManager or OrderManager not initialized");
            return;
        }
        
        double currentAsk = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double currentBid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        double slPrice = NormalizeDouble(m_currentStopLossPrice, _Digits);
        
        ENUM_ORDER_TYPE orderType;
        double entryPrice;
        
        // Determine direction based on SL position
        if(slPrice < currentBid)
        {
            // BUY market order (SL below current price)
            orderType = ORDER_TYPE_BUY;
            entryPrice = currentAsk;
            Print("Placing Immediate BUY Market Order");
        }
        else if(slPrice > currentAsk)
        {
            // SELL market order (SL above current price)
            orderType = ORDER_TYPE_SELL;
            entryPrice = currentBid;
            Print("Placing Immediate SELL Market Order");
        }
        else
        {
            Print("Error: Invalid Stop Loss position for immediate market order.");
            Print("For BUY: Stop Loss must be below current bid (", currentBid, ")");
            Print("For SELL: Stop Loss must be above current ask (", currentAsk, ")");
            return;
        }
        
        double tpPrice = m_riskManager.CalculateTakeProfitFromATR(orderType, entryPrice);
        
        if(tpPrice <= 0)
        {
            Print("Error: Invalid Take Profit calculated for immediate market order");
            return;
        }
        
        // Calculate position size
        double positionSize = m_riskManager.CalculatePositionSize(orderType, entryPrice, slPrice);
        
        if(positionSize <= 0)
        {
            Print("Error: Invalid position size calculated for immediate market order");
            return;
        }
        
        // Display trade information
        DisplayTradeInfo(orderType, entryPrice, slPrice, tpPrice, positionSize, "IMMEDIATE MARKET");
        
        CTrade* trade = m_orderManager.GetTrade();
        
        // Execute market order
        if(orderType == ORDER_TYPE_BUY)
        {
            if(trade.Buy(positionSize, Symbol(), entryPrice, slPrice, tpPrice, m_tradeComment))
            {
                Print("Immediate BUY Market Order executed successfully");
                m_orderManager.CancelNonEssentialPendingOrders();
            }
            else
            {
                Print("Immediate BUY Market Order failed. Error: ", GetLastError());
            }
        }
        else // ORDER_TYPE_SELL
        {
            if(trade.Sell(positionSize, Symbol(), entryPrice, slPrice, tpPrice, m_tradeComment))
            {
                Print("Immediate SELL Market Order executed successfully");
                m_orderManager.CancelNonEssentialPendingOrders();
            }
            else
            {
                Print("Immediate SELL Market Order failed. Error: ", GetLastError());
            }
        }
    }
    
    void UpdateCurrentValues(double stopLossPrice, ENUM_ALWAYS_IN_MODE alwaysInMode)
    {
        m_currentStopLossPrice = stopLossPrice;
        m_alwaysInMode = alwaysInMode;
    }
    
private:
    void DisplayTradeInfo(ENUM_ORDER_TYPE orderType, double entry, double sl, double tp, double lots, string orderTypeStr)
    {
        string direction = (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY) ? "BUY" : "SELL";
        double riskDistance = (direction == "BUY") ? (entry - sl) : (sl - entry);
        double rewardDistance = (direction == "BUY") ? (tp - entry) : (entry - tp);
        double actualRR = (riskDistance > 0) ? (rewardDistance / riskDistance) : 0;
        
        Print("=== TRADE SETUP (", orderTypeStr, ") ===");
        Print("Direction: ", direction);
        Print("Entry Price: ", DoubleToString(entry, _Digits));
        Print("Stop Loss: ", DoubleToString(sl, _Digits));
        Print("Take Profit: ", DoubleToString(tp, _Digits));
        Print("Position Size: ", DoubleToString(lots, 2), " lots");
        Print("Risk Distance: ", DoubleToString(riskDistance / _Point, 1), " points");
        Print("Reward Distance: ", DoubleToString(rewardDistance / _Point, 1), " points");
        Print("Actual R:R: 1:", DoubleToString(actualRR, 2));
        Print("Risk Amount: $", DoubleToString(m_riskManager.GetPreferredRisk(), 2));
        Print("Average Bars for TP: ", m_riskManager.GetAverageBars());
        Print("Always In Mode: ", EnumToString(m_alwaysInMode));
        Print("=================================");
    }
    
    string EnumToString(ENUM_ALWAYS_IN_MODE mode)
    {
        switch(mode)
        {
            case ALWAYS_IN_LONG: return "Always In Long";
            case ALWAYS_IN_SHORT: return "Always In Short";
            case ALWAYS_IN_UNCLEAR: return "Always In Unclear";
            default: return "Unknown";
        }
    }
};