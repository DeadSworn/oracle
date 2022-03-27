#include <sourcemod>
#include <colors>
#include <basecomm>
new bool:g_bIsInterval[MAXPLAYERS + 1];
public OnPluginStart()
{
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
}
public Action:SayCallback(iClient, const String:szCommand[], iArgc)
{
	if (!iClient) return Plugin_Continue;
	if (iClient <= 0) return Plugin_Continue;
	if(!IsClientInGame(iClient)) return Plugin_Continue;
	if (g_bIsInterval[iClient])	return Plugin_Handled;
	
	decl String:szArg[255], String:szChatMsg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);

	if(szArg[0] == '/' || szArg[0] == '!' || szArg[0] == '@' || BaseComm_IsClientGagged(iClient))	return Plugin_Continue;
	decl String:teamclient[18] = "";
	switch (GetClientTeam(iClient))
	{
		case 2: teamclient = "\x07FF4040";
		case 3: teamclient = "\x0799CCFF";
		default: teamclient = "\x07CCCCCC";
	}
	PrintToServer("%N: %s", iClient, szArg);
	FormatEx(szChatMsg, 255, "%s%N\x01 : %s", teamclient, iClient, szArg);
	CPrintToChatAllEx(iClient, szChatMsg);
	g_bIsInterval[iClient] = true;
	CreateTimer(0.75, Chat_Interval, iClient);
	return Plugin_Handled;
}
public Action:Chat_Interval(Handle:timer, any:iClient)
{
	g_bIsInterval[iClient] = false;
}