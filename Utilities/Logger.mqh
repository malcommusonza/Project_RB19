// Project RB19 - Logger (Enhanced)
// We're using the built-in Print function for now
// You can extend this with file logging, email alerts, etc.

class CLogger
{
public:
    static void Info(string message) { Print("[INFO] " + message); }
    static void Error(string message) { Print("[ERROR] " + message); }
    static void Trade(string message) { Print("[TRADE] " + message); }
};