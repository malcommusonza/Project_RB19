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
                if(m_positionInfo.Magic() == m_magicNumber)
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
                        newSL = prevLow - _Point;
                        Print("Adjusting LONG position SL. Previous Low: ", prevLow, ", New SL: ", newSL);
                    }
                    else if(posType == POSITION_TYPE_SELL)
                    {
                        // For short: SL = Previous High + 1 pip
                        newSL = prevHigh + _Point;
                        Print("Adjusting SHORT position SL. Previous High: ", prevHigh, ", New SL: ", newSL);
                    }
                    
                    newSL = NormalizeDouble(newSL, _Digits);
                    
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
            Print("No positions found with Magic Number: ", m_magicNumber);
        }
    }
    
    void QuickAdjustTakeProfit()
    {
        bool foundPosition = false;
        
        for(int i = PositionsTotal()-1; i >= 0; i--)
        {
            if(m_positionInfo.SelectByIndex(i))
            {
                if(m_positionInfo.Magic() == m_magicNumber)
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
                        newTP = prevHigh + _Point;
                        Print("Adjusting LONG position TP. Previous High: ", prevHigh, ", New TP: ", newTP);
                    }
                    else if(posType == POSITION_TYPE_SELL)
                    {
                        // For short: TP = Previous Low - 1 pip
                        newTP = prevLow - _Point;
                        Print("Adjusting SHORT position TP. Previous Low: ", prevLow, ", New TP: ", newTP);
                    }
                    
                    newTP = NormalizeDouble(newTP, _Digits);
                    
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
            Print("No positions found with Magic Number: ", m_magicNumber);
        }
    }
    
    void CancelNonEssentialPendingOrders()
    {
        int ordersCanceled = 0;
        
        for(int i = OrdersTotal()-1; i >= 0; i--)
        {
            if(m_orderInfo.SelectByIndex(i))
            {
                if(m_orderInfo.Magic() == m_magicNumber)
                {
                    // Check if it's a pending order (not SL/TP of market order)
                    if(m_orderInfo.OrderType() == ORDER_TYPE_BUY_LIMIT || 
                       m_orderInfo.OrderType() == ORDER_TYPE_SELL_LIMIT)
                    {
                        if(m_trade.OrderDelete(m_orderInfo.Ticket()))
                        {
                            ordersCanceled++;
                            Print("Canceled pending order #", m_orderInfo.Ticket());
                        }
                        else
                        {
                            Print("Failed to cancel pending order #", m_orderInfo.Ticket(), ". Error: ", GetLastError());
                        }
                    }
                }
            }
        }
        
        if(ordersCanceled > 0)
        {
            Print("Canceled ", ordersCanceled, " non-essential pending orders");
        }
    }
    
    // Getters
    CTrade* GetTrade() { return &m_trade; }
};