# Project RB19 - Advanced Trading EA

## Overview
Advanced MetaTrader 5 Expert Advisor with modular architecture, risk management, and GUI control panel.

## Features
- Modular design with separate risk management, order management, and trading engine
- GUI control panel with one-click operations
- Automated market monitoring with configurable trading bias
- Risk-managed position sizing
- Quick-adjust stop loss and take profit

## File Structure
- `Project_RB19.mq5` - Main EA file
- `Core/` - Core trading modules
- `UI/` - User interface components  
- `Resources/` - Constants and enumerations

## Installation
1. Copy all files to `MQL5/Experts/Project_RB19/` directory
2. Compile `Project_RB19.mq5`
3. Attach to chart and configure inputs

## Input Parameters
- **StopLossPrice** - Base stop loss price
- **PreferredRisk** - Risk amount in $
- **AverageBarsForTP** - Bars for average range calculation
- **MagicNumber** - Unique identifier for orders
- **AlwaysInMode** - Trading bias (Long/Short/Unclear)

## 🎯 Overall System Architecture
<img width="7171" height="1603" alt="deepseek_mermaid_20251130_737f79 (1)" src="https://github.com/user-attachments/assets/123538f4-4997-4475-bdd9-0c416c2037c4" />

## 📊 Detailed Component Flowchart
<img width="8577" height="10050" alt="deepseek_mermaid_20251130_fe5ba1" src="https://github.com/user-attachments/assets/3065d1f9-ff14-4a35-a447-87b21ae81277" />

## 🎨 User Interface Design
## Control Panel Layout
┌─────────────────────────────────┐
│        Advanced EA v1.0         │
├─────────────────────────────────┤
│                                 │
│  [ Place Limit Order ]    🔵    │
│  [ Monitor Market - OFF ] 🔴    │
│  [ Quick Adjust SL ]      🟠    │
│  [ Quick Adjust TP ]      🟠    │
│  [ Immediate Market Order ] 🟣  │
│                                 │
│  Current Parameters:            │
│  • SL: 1.08500                  │
│  • Risk: $50.00                 │
│  • Avg Bars: 5                  │
│  • Mode: Always In Unclear      │
│                                 │
└─────────────────────────────────┘


## Button	Default Color	Active Color	Function
Place Limit Order	Blue	-	Strategic entries at key levels
Monitor Market	Red	Green	Toggle automated trading
Quick Adjust SL	Orange	-	Fast stop loss adjustment
Quick Adjust TP	Orange	-	Fast take profit adjustment
Immediate Market	Purple	-	Instant market execution

## ⚙️ Core System Components
## 1. Trading Engine (CTrade Wrapper)
<img width="3366" height="231" alt="deepseek_mermaid_20251130_cfc4f0" src="https://github.com/user-attachments/assets/e012f5a8-d18b-4295-8e23-c66844326101" />

Key Functions:

PlaceLimitOrder() - Strategic pending orders

PlaceMarketOrder() - Automated entries

PlaceImmediateMarketOrder() - Manual market entries

QuickAdjustSL() - Position management

QuickAdjustTP() - Position management

**2. Risk Management System**
<img width="4194" height="1683" alt="deepseek_mermaid_20251130_f271aa" src="https://github.com/user-attachments/assets/2935312c-d20b-4000-8eff-0192da8ccb13" />

## Risk Calculation Formula:
Risk Points = Absolute(Entry Price - Stop Loss Price) / Point Size
Point Value = Profit per point movement for 1 lot
Position Size (Lots) = Preferred Risk $ / (Risk Points × Point Value)

## 3. Market Analysis Engine
<img width="3496" height="3117" alt="deepseek_mermaid_20251130_bf2e87" src="https://github.com/user-attachments/assets/66865d72-14e9-45a3-94e2-f90149147d6a" />

## 4. Order Management System
<img width="4853" height="2448" alt="deepseek_mermaid_20251130_5f9ae3" src="https://github.com/user-attachments/assets/e242b229-894d-41e0-8565-bf6f681e1537" />

## 🎯 Trading Logic Specifications

## Always In Mode Behavior
Mode	Trigger Condition	Action
Always In Long	Bear bar (Close ≤ Open) or Doji (Close = Open)	BUY Market Order
Always In Short	Bull bar (Close ≥ Open) or Doji (Close = Open)	SELL Market Order
Always In Unclear	Bear/Doji + SL Below Current = BUY
Bull/Doji + SL Above Current = SELL	Smart Direction

## Limit Order Placement Rules
Condition	Order Type	Entry Price
Stop Loss < Previous Low	BUY LIMIT	Previous Bar Low
Stop Loss > Previous High	SELL LIMIT	Previous Bar High

## Take Profit Calculation
Average Range = (Sum of (High - Low) for last X bars) / X
BUY Orders: TP = Entry Price + Average Range
SELL Orders: TP = Entry Price - Average Range
