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

<img width="7171" height="1603" alt="deepseek_mermaid_20251130_737f79 (1)" src="https://github.com/user-attachments/assets/123538f4-4997-4475-bdd9-0c416c2037c4" />
