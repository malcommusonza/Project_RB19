#property copyright "Copyright 2024, Project RB19"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Advanced EA with Risk Management - Project RB19"

// Include all modules
#include "Resources\Constants.mqh"
#include "Resources\Enums.mqh"
#include "Core\RiskManager.mqh"
#include "Core\OrderManager.mqh"
#include "Core\TradingEngine.mqh"
#include "UI\ControlPanel.mqh"

// Input parameters
input double   StopLossPrice = 0.0;        // Stop Loss Price
input double   PreferredRisk = 50.0;       // Preferred Risk in $
input int      AverageBarsForTP = 5;       // Bars for Average Range Calculation
input int      MagicNumber = 12345;        // Magic Number
input string   TradeComment = "ProjectRB19"; // Trade Comment
input ENUM_ALWAYS_IN_MODE AlwaysInMode = ALWAYS_IN_UNCLEAR; // Trading Bias

// Global instances of modules
CRiskManager       riskManager;
COrderManager      orderManager;
CTradingEngine     tradingEngine;
CControlPanel      controlPanel;

// Current values (for UI updates)
double currentStopLossPrice;
double currentPreferredRisk;
int currentAverageBarsForTP;
ENUM_ALWAYS_IN_MODE currentAlwaysInMode;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== Project RB19 Initialization ===");
   
   // Initialize current values from input parameters
   currentStopLossPrice = StopLossPrice;
   currentPreferredRisk = PreferredRisk;
   currentAverageBarsForTP = AverageBarsForTP;
   currentAlwaysInMode = AlwaysInMode;
   
   // Initialize modules in dependency order
   if(!riskManager.Initialize(currentPreferredRisk, currentAverageBarsForTP))
   {
      Print("Error: Risk Manager initialization failed");
      return INIT_FAILED;
   }
   
   if(!orderManager.Initialize(MagicNumber, TradeComment))
   {
      Print("Error: Order Manager initialization failed");
      return INIT_FAILED;
   }
   
   if(!tradingEngine.Initialize(MagicNumber, TradeComment, currentStopLossPrice, currentAlwaysInMode))
   {
      Print("Error: Trading Engine initialization failed");
      return INIT_FAILED;
   }
   
   // Pass trading engine pointer to control panel
   if(!controlPanel.Initialize(GetPointer(tradingEngine)))
   {
      Print("Error: Control Panel initialization failed");
      return INIT_FAILED;
   }
   
   // Set up module references - pass pointers using GetPointer()
   tradingEngine.SetRiskManager(GetPointer(riskManager));
   tradingEngine.SetOrderManager(GetPointer(orderManager));
   tradingEngine.SetControlPanel(GetPointer(controlPanel));
   
   Print("All modules initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   static uint lastUpdate = 0;  // Changed to uint to match GetTickCount()
   
   // Update status every second for performance
   if(GetTickCount() - lastUpdate > 1000)
   {
      controlPanel.UpdateStatusDisplay();
      lastUpdate = GetTickCount();
   }
   
   // Let trading engine handle market monitoring
   tradingEngine.OnTick();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   controlPanel.OnChartEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== Project RB19 Deinitialization ===");
   controlPanel.Cleanup();
   Print("All modules cleaned up successfully");
}