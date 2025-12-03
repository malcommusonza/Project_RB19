![deepseek_mermaid_20251130_b1a726](https://github.com/user-attachments/assets/adf36a10-c260-4841-9dfa-ccd16212ec03)

#Project RB19 - Advanced Trading Expert Advisor(EA)

The trading signal generating module for this EA implements the following research:

- **Moskowitz, T. J., Ooi, Y. H., & Pedersen, L. H. (2012). Time Series Momentum.** *Journal of Financial Economics, 104*(2), 228–250. [[DOI]](https://doi.org/10.1016/j.jfineco.2011.11.003)

The module is not included in this repository.

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

## ⚙️ Core System Components

## 1. Trading Engine (CTrade Wrapper)
<img width="3366" height="231" alt="deepseek_mermaid_20251130_cfc4f0" src="https://github.com/user-attachments/assets/e012f5a8-d18b-4295-8e23-c66844326101" />

## 2. Risk Management System
<img width="4194" height="1683" alt="deepseek_mermaid_20251130_f271aa" src="https://github.com/user-attachments/assets/2935312c-d20b-4000-8eff-0192da8ccb13" />


## 3. Market Analysis Engine
<img width="3496" height="3117" alt="deepseek_mermaid_20251130_bf2e87" src="https://github.com/user-attachments/assets/66865d72-14e9-45a3-94e2-f90149147d6a" />

## 4. Order Management System
<img width="4853" height="2448" alt="deepseek_mermaid_20251130_5f9ae3" src="https://github.com/user-attachments/assets/e242b229-894d-41e0-8565-bf6f681e1537" />

