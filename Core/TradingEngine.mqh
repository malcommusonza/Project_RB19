// Project RB19 - Main Trading Engine
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>

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
    
    // Position and Order checking
    CPositionInfo m_positionInfo;
    COrderInfo m_orderInfo;
    CTrade m_trade;
    
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
    
    void SetRiskManager(CRiskManager* riskMgr) { m_riskManager = riskMgr; }
    void SetOrderManager(COrderManager* orderMgr) { m_orderManager = orderMgr; }
    void SetControlPanel(CControlPanel* controlPanelPtr) { m_controlPanel = controlPanelPtr; }
    
    double GetCurrentATR()
    {
        if(m_riskManager != NULL)
        {
            return m_riskManager.GetCurrentATR();
        }
        return 0;
    }
    
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
        // Check for new bar
        CheckForNewBar();
    }
    
    void CheckForNewBar()
    {
        datetime currentBarTime = iTime(Symbol(), Period(), 0);
        
        if(currentBarTime != m_lastBarTime)
        {
            m_lastBarTime = (int)currentBarTime;
            
            // Check if we already have a position - if yes, turn off modes
            if(HasOpenPosition())
            {
                if(m_controlPanel != NULL)
                {
                    m_controlPanel.TurnOffBothModes();
                    CancelAllLimitOrders();
                    Print("Position detected: Both modes turned OFF and limit orders cancelled");
                }
                return; // Don't place any new orders
            }
            
            // No position exists, check modes
            if(m_controlPanel != NULL && m_controlPanel.IsLimitModeEnabled())
            {
                CheckAndPlaceLimitOrderOnNewBar();
            }
            
            if(m_controlPanel != NULL && m_controlPanel.IsMarketModeEnabled())
            {
                CheckMarketOrderConditions();
            }
        }
    }
    
    void CheckAndPlaceLimitOrderOnNewBar()
    {
        // Cancel any existing limit orders
        CancelAllLimitOrders();
        
        // Place new limit order
        PlaceLimitOrder();
    }
    
bool HasOpenPosition()
{
    // Remove this method and use OrderManager's version instead
    if(m_orderManager != NULL)
    {
        return m_orderManager.HasOpenPosition();
    }
    return false;
}

void CancelAllLimitOrders()
{
    // Remove this method and use OrderManager's version instead
    if(m_orderManager != NULL)
    {
        m_orderManager.CancelAllLimitOrders();
    }
}    
    void CheckMarketOrderConditions()
    {
        // First check if we already have a position
        if(HasOpenPosition())
        {
            Print("Skipping market order: Already have an open position");
            return;
        }
        
        double currentOpen = iOpen(Symbol(), Period(), 1);
        double currentClose = iClose(Symbol(), Period(), 1);
        double currentAsk = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double currentBid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        
        bool shouldBuy = false;
        bool shouldSell = false;
        
        switch(m_alwaysInMode)
        {
            case ALWAYS_IN_LONG:
                if(currentClose <= currentOpen)
                    shouldBuy = true;
                break;
                
            case ALWAYS_IN_SHORT:
                if(currentClose >= currentOpen)
                    shouldSell = true;
                break;
                
            case ALWAYS_IN_UNCLEAR:
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
        
        // Check if we already have a position
        if(HasOpenPosition())
        {
            Print("Cannot place limit order: Already have an open position");
            return;
        }
        
        // Get previous bar information
        double prevHigh = iHigh(Symbol(), Period(), 1);
        double prevLow = iLow(Symbol(), Period(), 1);
        
        // Get current spread
        double spreadPoints = (double)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
        double spreadPrice = spreadPoints * _Point;
        
        // Determine order direction and price
        ENUM_ORDER_TYPE orderType;
        double limitPrice;
        double slPrice = NormalizeDouble(m_currentStopLossPrice, _Digits);
        
        if(slPrice < prevLow)
        {
            // BUY LIMIT order (long position)
            orderType = ORDER_TYPE_BUY_LIMIT;
            
            // Adjust entry: previous bar low + spread
            limitPrice = prevLow + spreadPrice;
            Print("Auto-placing BUY LIMIT at previous bar low + spread: ", prevLow, " + ", spreadPrice, " = ", limitPrice);
            Print("Spread: ", spreadPoints, " points (", spreadPrice, " price units)");
            
            // Calculate take profit from ATR
            double tpPrice = m_riskManager.CalculateTakeProfitFromATR(orderType, limitPrice);
            
            if(tpPrice <= 0)
            {
                Print("Error: Invalid Take Profit calculated");
                return;
            }
            
            // Adjust TP for BUY: TP - spread
            tpPrice = tpPrice - spreadPrice;
            Print("Adjusted TP for BUY: Original TP ", (tpPrice + spreadPrice), " - spread ", spreadPrice, " = ", tpPrice);
            
            // Recalculate position size with adjusted prices
            double positionSize = m_riskManager.CalculatePositionSize(orderType, limitPrice, slPrice);
            
            if(positionSize <= 0)
            {
                Print("Error: Invalid position size calculated");
                return;
            }
            
            // Display trade information
            DisplayTradeInfo(orderType, limitPrice, slPrice, tpPrice, positionSize, "AUTO LIMIT (BUY)");
            
            // Place limit order
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_PENDING;
            request.symbol = Symbol();
            request.volume = positionSize;
            request.price = NormalizeDouble(limitPrice, _Digits);
            request.sl = NormalizeDouble(slPrice, _Digits);
            request.tp = NormalizeDouble(tpPrice, _Digits);
            request.type = orderType;
            request.magic = m_magicNumber;
            request.comment = m_tradeComment;
            request.type_filling = ORDER_FILLING_FOK;
            
            // Send order
            if(OrderSend(request, result))
            {
                Print("BUY LIMIT order auto-placed successfully!");
            }
            else
            {
                Print("BUY LIMIT order placement failed. Error: ", GetLastError());
            }
        }
        else if(slPrice > prevHigh)
        {
            // SELL LIMIT order (short position)
            orderType = ORDER_TYPE_SELL_LIMIT;
            
            // Entry remains at previous bar high
            limitPrice = prevHigh;
            Print("Auto-placing SELL LIMIT at previous bar high: ", limitPrice);
            Print("Spread: ", spreadPoints, " points (", spreadPrice, " price units)");
            
            // Calculate take profit from ATR
            double tpPrice = m_riskManager.CalculateTakeProfitFromATR(orderType, limitPrice);
            
            if(tpPrice <= 0)
            {
                Print("Error: Invalid Take Profit calculated");
                return;
            }
            
            // Adjust TP for SELL: TP + spread
            tpPrice = tpPrice + spreadPrice;
            Print("Adjusted TP for SELL: Original TP ", (tpPrice - spreadPrice), " + spread ", spreadPrice, " = ", tpPrice);
            
            // Adjust SL for SELL: SL + spread
            double adjustedSlPrice = slPrice + spreadPrice;
            Print("Adjusted SL for SELL: Original SL ", slPrice, " + spread ", spreadPrice, " = ", adjustedSlPrice);
            
            // Recalculate position size with adjusted prices
            double positionSize = m_riskManager.CalculatePositionSize(orderType, limitPrice, adjustedSlPrice);
            
            if(positionSize <= 0)
            {
                Print("Error: Invalid position size calculated");
                return;
            }
            
            // Display trade information
            DisplayTradeInfo(orderType, limitPrice, adjustedSlPrice, tpPrice, positionSize, "AUTO LIMIT (SELL)");
            
            // Place limit order
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_PENDING;
            request.symbol = Symbol();
            request.volume = positionSize;
            request.price = NormalizeDouble(limitPrice, _Digits);
            request.sl = NormalizeDouble(adjustedSlPrice, _Digits);
            request.tp = NormalizeDouble(tpPrice, _Digits);
            request.type = orderType;
            request.magic = m_magicNumber;
            request.comment = m_tradeComment;
            request.type_filling = ORDER_FILLING_FOK;
            
            // Send order
            if(OrderSend(request, result))
            {
                Print("SELL LIMIT order auto-placed successfully!");
            }
            else
            {
                Print("SELL LIMIT order placement failed. Error: ", GetLastError());
            }
        }
        else
        {
            Print("Cannot place limit order: Invalid Stop Loss position.");
            Print("For BUY LIMIT: Stop Loss must be below previous bar low (", prevLow, ")");
            Print("For SELL LIMIT: Stop Loss must be above previous bar high (", prevHigh, ")");
        }
    }
    
    void PlaceMarketOrder(ENUM_ORDER_TYPE orderType)
    {
        if(m_riskManager == NULL || m_orderManager == NULL)
        {
            Print("Error: RiskManager or OrderManager not initialized");
            return;
        }
        
        // Check if we already have a position
        if(HasOpenPosition())
        {
            Print("Cannot place market order: Already have an open position");
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
        bool orderSuccess = false;
        
        // Execute market order
        if(orderType == ORDER_TYPE_BUY)
        {
            if(trade.Buy(positionSize, Symbol(), entryPrice, slPrice, tpPrice, m_tradeComment))
            {
                Print("BUY Market Order executed successfully");
                orderSuccess = true;
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
                orderSuccess = true;
            }
            else
            {
                Print("SELL Market Order failed. Error: ", GetLastError());
            }
        }
        
        // If order was successful, cancel pending orders and turn off modes
        if(orderSuccess)
        {
            m_orderManager.CancelNonEssentialPendingOrders();
            
            // Turn off both modes
            if(m_controlPanel != NULL)
            {
                m_controlPanel.TurnOffBothModes();
                Print("Market order filled: Both modes turned OFF");
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
        
        // Check if we already have a position
        if(HasOpenPosition())
        {
            Print("Cannot place immediate market order: Already have an open position");
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
            orderType = ORDER_TYPE_BUY;
            entryPrice = currentAsk;
            Print("Placing Immediate BUY Market Order");
        }
        else if(slPrice > currentAsk)
        {
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
        bool orderSuccess = false;
        
        // Execute market order
        if(orderType == ORDER_TYPE_BUY)
        {
            if(trade.Buy(positionSize, Symbol(), entryPrice, slPrice, tpPrice, m_tradeComment))
            {
                Print("Immediate BUY Market Order executed successfully");
                orderSuccess = true;
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
                orderSuccess = true;
            }
            else
            {
                Print("Immediate SELL Market Order failed. Error: ", GetLastError());
            }
        }
        
        // If order was successful, cancel pending orders and turn off modes
        if(orderSuccess)
        {
            m_orderManager.CancelNonEssentialPendingOrders();
            
            // Turn off both modes
            if(m_controlPanel != NULL)
            {
                m_controlPanel.TurnOffBothModes();
                Print("Immediate market order filled: Both modes turned OFF");
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