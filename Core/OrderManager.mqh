// Project RB19 - Order Management Module
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>

class COrderManager
{
private:
    CTrade m_trade;
    CPositionInfo m_positionInfo;
    COrderInfo m_orderInfo;
    int m_magicNumber;
    
public:
    COrderManager() : m_magicNumber(0) {}
    
    bool Initialize(int magicNumber, string tradeComment)
    {
        m_magicNumber = magicNumber;
        m_trade.SetExpertMagicNumber(m_magicNumber);
        m_trade.SetMarginMode();
        m_trade.SetTypeFillingBySymbol(Symbol());
        Print("Order Manager initialized");
        return true;
    }
    
    void QuickAdjustStopLoss()
    {
        bool foundPosition = false;
        
        for(int i = PositionsTotal()-1; i >= 0; i--)
        {
            if(m_positionInfo.SelectByIndex(i))
            {
                if(m_positionInfo.Magic() == m_magicNumber && 
                   m_positionInfo.Symbol() == Symbol())
                {
                    foundPosition = true;
                    ENUM_POSITION_TYPE posType = m_positionInfo.PositionType();
                    ulong ticket = m_positionInfo.Ticket();
                    
                    double prevHigh = iHigh(Symbol(), Period(), 1);
                    double prevLow = iLow(Symbol(), Period(), 1);
                    double newSL = 0;
                    
                    if(posType == POSITION_TYPE_BUY)
                    {
                        // For long: SL = Previous Low - 1 pip
                        newSL = prevLow - (10 * _Point); // 1 pip = 10 points for 5-digit brokers
                        Print("Adjusting LONG position SL. Previous Low: ", prevLow, ", New SL: ", newSL);
                    }
                    else if(posType == POSITION_TYPE_SELL)
                    {
                        // For short: SL = Previous High + 1 pip
                        newSL = prevHigh + (10 * _Point);
                        Print("Adjusting SHORT position SL. Previous High: ", prevHigh, ", New SL: ", newSL);
                    }
                    
                    newSL = NormalizeDouble(newSL, _Digits);
                    
                    // Validate new SL position
                    if(posType == POSITION_TYPE_BUY && newSL >= m_positionInfo.PriceOpen())
                    {
                        Print("Error: New SL for BUY must be below entry price");
                        continue;
                    }
                    else if(posType == POSITION_TYPE_SELL && newSL <= m_positionInfo.PriceOpen())
                    {
                        Print("Error: New SL for SELL must be above entry price");
                        continue;
                    }
                    
                    // Modify position
                    if(m_trade.PositionModify(ticket, newSL, m_positionInfo.TakeProfit()))
                    {
                        Print("Successfully adjusted SL for position #", ticket);
                    }
                    else
                    {
                        Print("Failed to adjust SL for position #", ticket, ". Error: ", GetLastError());
                    }
                }
            }
        }
        
        if(!foundPosition)
        {
            Print("No positions found with Magic Number: ", m_magicNumber, " for symbol: ", Symbol());
        }
    }
    
    void QuickAdjustTakeProfit()
    {
        bool foundPosition = false;
        
        for(int i = PositionsTotal()-1; i >= 0; i--)
        {
            if(m_positionInfo.SelectByIndex(i))
            {
                if(m_positionInfo.Magic() == m_magicNumber && 
                   m_positionInfo.Symbol() == Symbol())
                {
                    foundPosition = true;
                    ENUM_POSITION_TYPE posType = m_positionInfo.PositionType();
                    ulong ticket = m_positionInfo.Ticket();
                    
                    double prevHigh = iHigh(Symbol(), Period(), 1);
                    double prevLow = iLow(Symbol(), Period(), 1);
                    double newTP = 0;
                    
                    if(posType == POSITION_TYPE_BUY)
                    {
                        // For long: TP = Previous High + 1 pip
                        newTP = prevHigh + (10 * _Point);
                        Print("Adjusting LONG position TP. Previous High: ", prevHigh, ", New TP: ", newTP);
                    }
                    else if(posType == POSITION_TYPE_SELL)
                    {
                        // For short: TP = Previous Low - 1 pip
                        newTP = prevLow - (10 * _Point);
                        Print("Adjusting SHORT position TP. Previous Low: ", prevLow, ", New TP: ", newTP);
                    }
                    
                    newTP = NormalizeDouble(newTP, _Digits);
                    
                    // Validate new TP position
                    if(posType == POSITION_TYPE_BUY && newTP <= m_positionInfo.PriceOpen())
                    {
                        Print("Error: New TP for BUY must be above entry price");
                        continue;
                    }
                    else if(posType == POSITION_TYPE_SELL && newTP >= m_positionInfo.PriceOpen())
                    {
                        Print("Error: New TP for SELL must be below entry price");
                        continue;
                    }
                    
                    // Modify position
                    if(m_trade.PositionModify(ticket, m_positionInfo.StopLoss(), newTP))
                    {
                        Print("Successfully adjusted TP for position #", ticket);
                    }
                    else
                    {
                        Print("Failed to adjust TP for position #", ticket, ". Error: ", GetLastError());
                    }
                }
            }
        }
        
        if(!foundPosition)
        {
            Print("No positions found with Magic Number: ", m_magicNumber, " for symbol: ", Symbol());
        }
    }
    
    void CancelAllLimitOrders()
    {
        int ordersCanceled = 0;
        
        for(int i = OrdersTotal()-1; i >= 0; i--)
        {
            ulong orderTicket = OrderGetTicket(i);
            if(orderTicket > 0)
            {
                if(m_orderInfo.Select(orderTicket))
                {
                    if(m_orderInfo.Magic() == m_magicNumber && 
                       m_orderInfo.Symbol() == Symbol())
                    {
                        // Check if it's a pending order (limit order)
                        ENUM_ORDER_TYPE orderType = m_orderInfo.OrderType();
                        if(orderType == ORDER_TYPE_BUY_LIMIT || 
                           orderType == ORDER_TYPE_SELL_LIMIT ||
                           orderType == ORDER_TYPE_BUY_STOP ||
                           orderType == ORDER_TYPE_SELL_STOP)
                        {
                            if(m_trade.OrderDelete(orderTicket))
                            {
                                ordersCanceled++;
                                Print("Canceled pending order #", orderTicket);
                            }
                            else
                            {
                                Print("Failed to cancel pending order #", orderTicket, ". Error: ", GetLastError());
                            }
                        }
                    }
                }
            }
        }
        
        if(ordersCanceled > 0)
        {
            Print("Canceled ", ordersCanceled, " pending orders");
        }
        else
        {
            Print("No pending orders found to cancel");
        }
    }
    
    // Alternative method name for compatibility
    void CancelNonEssentialPendingOrders()
    {
        CancelAllLimitOrders();
    }
    
    // New method: Check if we have open positions
    bool HasOpenPosition()
    {
        for(int i = PositionsTotal()-1; i >= 0; i--)
        {
            if(m_positionInfo.SelectByIndex(i))
            {
                if(m_positionInfo.Magic() == m_magicNumber && 
                   m_positionInfo.Symbol() == Symbol())
                {
                    return true;
                }
            }
        }
        return false;
    }
    
    // New method: Get number of open positions
    int GetOpenPositionsCount()
    {
        int count = 0;
        for(int i = PositionsTotal()-1; i >= 0; i--)
        {
            if(m_positionInfo.SelectByIndex(i))
            {
                if(m_positionInfo.Magic() == m_magicNumber && 
                   m_positionInfo.Symbol() == Symbol())
                {
                    count++;
                }
            }
        }
        return count;
    }
    
    // New method: Close all open positions
    bool CloseAllPositions()
    {
        bool allClosed = true;
        int closedCount = 0;
        
        for(int i = PositionsTotal()-1; i >= 0; i--)
        {
            if(m_positionInfo.SelectByIndex(i))
            {
                if(m_positionInfo.Magic() == m_magicNumber && 
                   m_positionInfo.Symbol() == Symbol())
                {
                    ulong ticket = m_positionInfo.Ticket();
                    ENUM_POSITION_TYPE posType = m_positionInfo.PositionType();
                    
                    if(posType == POSITION_TYPE_BUY)
                    {
                        if(m_trade.PositionClose(ticket))
                        {
                            closedCount++;
                            Print("Closed BUY position #", ticket);
                        }
                        else
                        {
                            allClosed = false;
                            Print("Failed to close BUY position #", ticket, ". Error: ", GetLastError());
                        }
                    }
                    else if(posType == POSITION_TYPE_SELL)
                    {
                        if(m_trade.PositionClose(ticket))
                        {
                            closedCount++;
                            Print("Closed SELL position #", ticket);
                        }
                        else
                        {
                            allClosed = false;
                            Print("Failed to close SELL position #", ticket, ". Error: ", GetLastError());
                        }
                    }
                }
            }
        }
        
        if(closedCount > 0)
        {
            Print("Closed ", closedCount, " positions");
        }
        
        return allClosed;
    }
    
    // Getters
    CTrade* GetTrade() { return &m_trade; }
    int GetMagicNumber() const { return m_magicNumber; }
};