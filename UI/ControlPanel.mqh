// Project RB19 - Control Panel Module
#include <ChartObjects/ChartObjectsTxtControls.mqh>
#include "C:\Users\Malcom\AppData\Roaming\MetaQuotes\Terminal\10CE948A1DFC9A8C27E56E827008EBD4\MQL5\Experts\Project_RB19\Resources\Constants.mqh"

// Forward declarations
class CTradingEngine;

class CControlPanel
{
private:
    CChartObjectButton m_btnLimitMode;
    CChartObjectButton m_btnMarketMode;
    CChartObjectButton m_btnQuickAdjustSL;
    CChartObjectButton m_btnQuickAdjustTP;
    CChartObjectButton m_btnImmediateMarket;
    
    // ATR Display Label
    CChartObjectLabel m_lblATR;
    
    bool m_limitModeEnabled;
    bool m_marketModeEnabled;
    
    // Reference to trading engine
    CTradingEngine* m_tradingEngine;
    
public:
    CControlPanel() : 
        m_limitModeEnabled(false),
        m_marketModeEnabled(false),
        m_tradingEngine(NULL)
    {}
    
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
        
        // Create ATR Display Label at the TOP
        if(!m_lblATR.Create(0, "lblATR", 0, x, y))
            return false;
        
        m_lblATR.Description("ATR: Loading...");
        m_lblATR.Color(clrBlue);
        m_lblATR.FontSize(9);
        ObjectSetInteger(0, "lblATR", OBJPROP_XSIZE, BUTTON_WIDTH);
        ObjectSetInteger(0, "lblATR", OBJPROP_YSIZE, 20);
        ObjectSetInteger(0, "lblATR", OBJPROP_ALIGN, ALIGN_LEFT);
        ObjectSetInteger(0, "lblATR", OBJPROP_BGCOLOR, COLOR_PANEL_BACKGROUND);
        ObjectSetInteger(0, "lblATR", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, "lblATR", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, "lblATR", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, "lblATR", OBJPROP_BACK, false);
        
        y += 25; // Space after ATR label
        
        // Create "Mode: Enter on Limit" button
        if(!m_btnLimitMode.Create(0, "btnLimitMode", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnLimitMode.Description("Mode: Enter on Limit - OFF");
        m_btnLimitMode.Color(COLOR_BUTTON_WHITE);
        m_btnLimitMode.FontSize(9);
        ObjectSetInteger(0, "btnLimitMode", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
        
        y += BUTTON_SPACING;
        
        // Create "Mode: Enter at M on IP" button (renamed from Monitor Market)
        if(!m_btnMarketMode.Create(0, "btnMarketMode", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnMarketMode.Description("Mode: Enter at M on IP - OFF");
        m_btnMarketMode.Color(COLOR_BUTTON_WHITE);
        m_btnMarketMode.FontSize(9);
        ObjectSetInteger(0, "btnMarketMode", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
        
        y += BUTTON_SPACING;
        
        // Create Immediate Market Order button
        if(!m_btnImmediateMarket.Create(0, "btnImmediateMarket", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnImmediateMarket.Description("Immediate Market Order");
        m_btnImmediateMarket.Color(COLOR_BUTTON_WHITE);
        m_btnImmediateMarket.FontSize(9);
        ObjectSetInteger(0, "btnImmediateMarket", OBJPROP_BGCOLOR, COLOR_BUTTON_PURPLE);
        
        y += BUTTON_SPACING;
        
        // Create Quick Adjust TP button
        if(!m_btnQuickAdjustTP.Create(0, "btnQuickAdjustTP", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnQuickAdjustTP.Description("Quick Adjust TP");
        m_btnQuickAdjustTP.Color(COLOR_BUTTON_WHITE);
        m_btnQuickAdjustTP.FontSize(9);
        ObjectSetInteger(0, "btnQuickAdjustTP", OBJPROP_BGCOLOR, COLOR_BUTTON_ORANGE);
        
        y += BUTTON_SPACING;
        
        // Create Quick Adjust SL button
        if(!m_btnQuickAdjustSL.Create(0, "btnQuickAdjustSL", 0, x, y, BUTTON_WIDTH, BUTTON_HEIGHT))
            return false;
        m_btnQuickAdjustSL.Description("Quick Adjust SL");
        m_btnQuickAdjustSL.Color(COLOR_BUTTON_WHITE);
        m_btnQuickAdjustSL.FontSize(9);
        ObjectSetInteger(0, "btnQuickAdjustSL", OBJPROP_BGCOLOR, COLOR_BUTTON_ORANGE);
        
        // Initial update of ATR display
        UpdateATRDisplay();
        
        return true;
    }
    
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if(id == CHARTEVENT_OBJECT_CLICK)
        {
            if(m_tradingEngine == NULL) return;
            
            if(sparam == "btnLimitMode")
            {
                Print("Limit Mode button clicked");
                ToggleLimitMode();
            }
            else if(sparam == "btnMarketMode")
            {
                Print("Market Mode button clicked");
                ToggleMarketMode();
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
        else if(id == CHARTEVENT_CHART_CHANGE)
        {
            UpdateATRDisplay();
        }
    }
    
    void ToggleLimitMode()
    {
        m_limitModeEnabled = !m_limitModeEnabled;
        
        if(m_limitModeEnabled)
        {
            m_btnLimitMode.Description("Mode: Enter on Limit - ON");
            ObjectSetInteger(0, "btnLimitMode", OBJPROP_BGCOLOR, COLOR_BUTTON_GREEN);
            Print("Limit order mode ENABLED - Placing immediate limit order");
            
            // Immediately place a limit order when turned ON
            if(m_tradingEngine != NULL)
            {
                m_tradingEngine.ImmediatePlaceLimitOrder();
            }
        }
        else
        {
            m_btnLimitMode.Description("Mode: Enter on Limit - OFF");
            ObjectSetInteger(0, "btnLimitMode", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
            Print("Limit order mode DISABLED");
            
            // Cancel any pending limit orders when turned OFF
            if(m_tradingEngine != NULL)
            {
                m_tradingEngine.CancelAllLimitOrders();
            }
        }
    }
    
    void ToggleMarketMode()
    {
        m_marketModeEnabled = !m_marketModeEnabled;
        
        if(m_marketModeEnabled)
        {
            m_btnMarketMode.Description("Mode: Enter at M on IP - ON");
            ObjectSetInteger(0, "btnMarketMode", OBJPROP_BGCOLOR, COLOR_BUTTON_GREEN);
            Print("Market order mode ENABLED");
        }
        else
        {
            m_btnMarketMode.Description("Mode: Enter at M on IP - OFF");
            ObjectSetInteger(0, "btnMarketMode", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
            Print("Market order mode DISABLED");
        }
    }
    
    void TurnOffBothModes()
    {
        if(m_limitModeEnabled)
        {
            m_limitModeEnabled = false;
            m_btnLimitMode.Description("Mode: Enter on Limit - OFF");
            ObjectSetInteger(0, "btnLimitMode", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
            Print("Limit order mode turned OFF (position entered)");
        }
        
        if(m_marketModeEnabled)
        {
            m_marketModeEnabled = false;
            m_btnMarketMode.Description("Mode: Enter at M on IP - OFF");
            ObjectSetInteger(0, "btnMarketMode", OBJPROP_BGCOLOR, COLOR_BUTTON_RED);
            Print("Market order mode turned OFF (position entered)");
        }
    }
    
    bool IsLimitModeEnabled() const { return m_limitModeEnabled; }
    bool IsMarketModeEnabled() const { return m_marketModeEnabled; }
    
    void UpdateStatusDisplay()
    {
        UpdateATRDisplay();
    }
    
    void UpdateATRDisplay()
    {
        if(m_tradingEngine == NULL) 
        {
            m_lblATR.Description("ATR: No Engine");
            return;
        }
        
        double atrValue = m_tradingEngine.GetCurrentATR();
        
        string atrText;
        if(atrValue > 0)
        {
            double atrPoints = atrValue / _Point;
            atrText = StringFormat("ATR: %.5f (%d pts)", atrValue, (int)atrPoints);
        }
        else
        {
            atrText = "ATR: N/A";
        }
        
        m_lblATR.Description(atrText);
    }
    
    void Cleanup()
    {
        m_btnLimitMode.Delete();
        m_btnMarketMode.Delete();
        m_btnQuickAdjustSL.Delete();
        m_btnQuickAdjustTP.Delete();
        m_btnImmediateMarket.Delete();
        m_lblATR.Delete();
    }
};