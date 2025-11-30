// Project RB19 - Control Panel Module
#include <ChartObjects/ChartObjectsTxtControls.mqh>
#include "C:\Users\Malcom\AppData\Roaming\MetaQuotes\Terminal\10CE948A1DFC9A8C27E56E827008EBD4\MQL5\Experts\Project_RB19\Resources\Constants.mqh"

// Forward declarations
class CTradingEngine;

class CControlPanel
{
private:
    CChartObjectButton m_btnPlaceLimit;
    CChartObjectButton m_btnMonitorMarket;
    CChartObjectButton m_btnQuickAdjustSL;
    CChartObjectButton m_btnQuickAdjustTP;
    CChartObjectButton m_btnImmediateMarket;
    
    bool m_monitoringEnabled;
    
    // Reference to trading engine
    CTradingEngine* m_tradingEngine;
    
public:
    CControlPanel() : 
        m_monitoringEnabled(false),
        m_tradingEngine(NULL)
    {}
    
    // FIX: Change parameter name to avoid conflict with global variable
    bool Initialize(CTradingEngine* enginePtr)
    {
        m_tradingEngine = enginePtr;
        if(!CreateControlPanel())
        {
            Print("Error: Failed to create control panel");
            return false;
        }
        Print("Control Panel initialized");
        return true;
    }
    
    bool CreateControlPanel()
    {
        int x = PANEL_START_X;
        int y = PANEL_START_Y;
        
        // Create Place Limit Order button
        if(!m_btnPlaceLimit.Create(0, "btnPlaceLimit", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnPlaceLimit.Description("Place Limit Order");
        m_btnPlaceLimit.Color(COLOR_BUTTON_WHITE);
        m_btnPlaceLimit.FontSize(9);
        ObjectSetInteger(0, "btnPlaceLimit", OBJPROP_BGCOLOR, COLOR_BUTTON_BLUE);
        
        y += BUTTON_SPACING;
        
        // Create Monitor Market Orders button
        if(!m_btnMonitorMarket.Create(0, "btnMonitorMarket", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnMonitorMarket.Description("Monitor Market - OFF");
        m_btnMonitorMarket.Color(COLOR_BUTTON_WHITE);
        m_btnMonitorMarket.FontSize(9);
        ObjectSetInteger(0, "btnMonitorMarket", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
        
        y += BUTTON_SPACING;
        
        // Create Quick Adjust SL button
        if(!m_btnQuickAdjustSL.Create(0, "btnQuickAdjustSL", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnQuickAdjustSL.Description("Quick Adjust SL");
        m_btnQuickAdjustSL.Color(COLOR_BUTTON_WHITE);
        m_btnQuickAdjustSL.FontSize(9);
        ObjectSetInteger(0, "btnQuickAdjustSL", OBJPROP_BGCOLOR, COLOR_BUTTON_ORANGE);
        
        y += BUTTON_SPACING;
        
        // Create Quick Adjust TP button
        if(!m_btnQuickAdjustTP.Create(0, "btnQuickAdjustTP", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnQuickAdjustTP.Description("Quick Adjust TP");
        m_btnQuickAdjustTP.Color(COLOR_BUTTON_WHITE);
        m_btnQuickAdjustTP.FontSize(9);
        ObjectSetInteger(0, "btnQuickAdjustTP", OBJPROP_BGCOLOR, COLOR_BUTTON_ORANGE);
        
        y += BUTTON_SPACING;
        
        // Create Immediate Market Order button
        if(!m_btnImmediateMarket.Create(0, "btnImmediateMarket", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnImmediateMarket.Description("Immediate Market Order");
        m_btnImmediateMarket.Color(COLOR_BUTTON_WHITE);
        m_btnImmediateMarket.FontSize(9);
        ObjectSetInteger(0, "btnImmediateMarket", OBJPROP_BGCOLOR, COLOR_BUTTON_PURPLE);
        
        return true;
    }
    
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if(id == CHARTEVENT_OBJECT_CLICK)
        {
            if(m_tradingEngine == NULL) return;
            
            if(sparam == "btnPlaceLimit")
            {
                Print("Place Limit Order button clicked");
                m_tradingEngine.PlaceLimitOrder();
            }
            else if(sparam == "btnMonitorMarket")
            {
                Print("Monitor Market button clicked");
                ToggleMarketMonitoring();
            }
            else if(sparam == "btnQuickAdjustSL")
            {
                Print("Quick Adjust SL button clicked");
                m_tradingEngine.QuickAdjustSL();
            }
            else if(sparam == "btnQuickAdjustTP")
            {
                Print("Quick Adjust TP button clicked");
                m_tradingEngine.QuickAdjustTP();
            }
            else if(sparam == "btnImmediateMarket")
            {
                Print("Immediate Market Order button clicked");
                m_tradingEngine.PlaceImmediateMarketOrder();
            }
        }
    }
    
    void ToggleMarketMonitoring()
    {
        m_monitoringEnabled = !m_monitoringEnabled;
        
        if(m_monitoringEnabled)
        {
            m_btnMonitorMarket.Description("Monitor Market - ON");
            ObjectSetInteger(0, "btnMonitorMarket", OBJPROP_BGCOLOR, COLOR_BUTTON_GREEN);
            Print("Market order monitoring ENABLED");
        }
        else
        {
            m_btnMonitorMarket.Description("Monitor Market - OFF");
            ObjectSetInteger(0, "btnMonitorMarket", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
            Print("Market order monitoring DISABLED");
        }
    }
    
    bool IsMonitoringEnabled() { return m_monitoringEnabled; }
    
    void UpdateStatusDisplay()
    {
        if(m_monitoringEnabled)
        {
            m_btnMonitorMarket.Description("Monitor Market - ON");
            ObjectSetInteger(0, "btnMonitorMarket", OBJPROP_BGCOLOR, COLOR_BUTTON_GREEN);
        }
        else
        {
            m_btnMonitorMarket.Description("Monitor Market - OFF");
            ObjectSetInteger(0, "btnMonitorMarket", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
        }
    }
    
    void Cleanup()
    {
        m_btnPlaceLimit.Delete();
        m_btnMonitorMarket.Delete();
        m_btnQuickAdjustSL.Delete();
        m_btnQuickAdjustTP.Delete();
        m_btnImmediateMarket.Delete();
    }
};