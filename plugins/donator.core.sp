#include <sourcemod>
#include <clientprefs>
#include <donator>
#include <sdktools>
new Handle:g_hForward_OnDonatorConnect = INVALID_HANDLE;
new Handle:g_hForward_OnPostDonatorCheck = INVALID_HANDLE;
new Handle:g_CookieTag = INVALID_HANDLE;
new Handle:g_hMenuItems = INVALID_HANDLE;
new Handle:g_hDonatorTagTrie = INVALID_HANDLE;
new g_iMenuId, g_iMenuCount;
public OnPluginStart()
{
	g_CookieTag = RegClientCookie("donator.core.tag", "Donator tag", CookieAccess_Public);
	g_hForward_OnDonatorConnect = CreateGlobalForward("OnDonatorConnect", ET_Event, Param_Cell);
	g_hForward_OnPostDonatorCheck = CreateGlobalForward("OnPostDonatorCheck", ET_Event, Param_Cell);
	g_hDonatorTagTrie = CreateTrie();
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
	g_hMenuItems = CreateArray();
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("donator.core");
	CreateNative("GetDonatorMessage", Native_GetDonatorMessage);
	CreateNative("SetDonatorMessage", Native_SetDonatorMessage);
	CreateNative("Donator_RegisterMenuItem", Native_RegisterMenuItem);
	CreateNative("Donator_UnregisterMenuItem", Native_UnregisterMenuItem);
	return APLRes_Success;
}
public Action:SayCallback(iClient, const String:command[], argc)
{
	if(!iClient) return Plugin_Continue;
	decl String:szArg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);
	
	if (StrEqual(szArg, "!menu", false) || StrEqual(szArg, "menu", false) || StrEqual(szArg, "/menu", false))
	{
		ShowDonatorMenu(iClient);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:ShowDonatorMenu(client)
{
	new Handle:menu = CreateMenu(DonatorMenuSelected);
	SetMenuTitle(menu,"Donator Menu");

	decl Handle:hItem, String:szBuffer[64], String:szItem[4];
	for(new i = 0; i < GetArraySize(g_hMenuItems); i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		hItem = GetArrayCell(g_hMenuItems, i);
		GetArrayString(hItem, 1, szBuffer, sizeof(szBuffer));
		AddMenuItem(menu, szItem, szBuffer, ITEMDRAW_DEFAULT);
	}
	DisplayMenu(menu, client, 20);
}
public DonatorMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);
	switch (action)
	{
		case MenuAction_Select:
		{
			new Handle:hItem = GetArrayCell(g_hMenuItems, iSelected);
			new Handle:hFwd = GetArrayCell(hItem, 3);
			new bool:result;
			Call_StartForward(hFwd);
			Call_PushCell(param1);
			Call_Finish(result);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}
public Native_RegisterMenuItem(Handle:hPlugin, iNumParams)
{
	decl String:szCallerName[PLATFORM_MAX_PATH], String:szBuffer[256], String:szMenuTitle[256];
	GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
	
	new Handle:hFwd = CreateForward(ET_Single, Param_Cell, Param_CellByRef);	
	if (!AddToForward(hFwd, hPlugin, GetNativeCell(2)))
		ThrowError("Failed to add forward from %s", szCallerName);

	GetNativeString(1, szMenuTitle, 255);
	
	new Handle:hTempItem;
	for (new i = 0; i < g_iMenuCount; i++)	//make sure we aren't double registering
	{
		hTempItem = GetArrayCell(g_hMenuItems, i);
		GetArrayString(hTempItem, 1, szBuffer, sizeof(szBuffer));
		if (StrEqual(szMenuTitle, szBuffer))
		{
			RemoveFromArray(g_hMenuItems, i);
			g_iMenuCount--;
		}
	}
	
	new Handle:hItem = CreateArray(15);
	new id = g_iMenuId++;
	g_iMenuCount++;
	PushArrayString(hItem, szCallerName);
	PushArrayString(hItem, szMenuTitle);
	PushArrayCell(hItem, id);
	PushArrayCell(hItem, hFwd);
	PushArrayCell(g_hMenuItems, hItem);
	return id;
}
public Native_UnregisterMenuItem(Handle:hPlugin, iNumParams)
{
	new Handle:hTempItem;
	for (new i = 0; i < g_iMenuCount; i++)
	{
		hTempItem = GetArrayCell(g_hMenuItems, i);
		new id = GetArrayCell(hTempItem, 2);
		if (id == GetNativeCell(1))
		{
			RemoveFromArray(g_hMenuItems, i);
			g_iMenuCount--;
			return true;
		}
	}
	return false;
}
public OnClientAuthorized(iClient, const String:szAuthId[])
{
	if(IsFakeClient(iClient)) return;
	Forward_OnDonatorConnect(iClient);
}
public OnClientPostAdminCheck(iClient)
{
	if(IsFakeClient(iClient)) return;
	if (AreClientCookiesCached(iClient))
	{
		decl String:szTagBuffer[256], String:szSteamId[64];
		GetClientCookie(iClient, g_CookieTag, szTagBuffer, sizeof(szTagBuffer));
		GetClientAuthString(iClient, szSteamId, sizeof(szSteamId));
		if (strlen(szTagBuffer) > 1)
		{
			SetTrieString(g_hDonatorTagTrie, szSteamId, szTagBuffer, true);
		}
	}
	Forward_OnPostDonatorCheck(iClient);
}
public Native_GetDonatorMessage(Handle:plugin, params)
{
	decl String:szBuffer[256], String:szSteamId[64];
	GetClientAuthString(GetNativeCell(1), szSteamId, sizeof(szSteamId));

	if (GetTrieString(g_hDonatorTagTrie, szSteamId, szBuffer, 256))
	{
		SetNativeString(2, szBuffer, 256, true);
		return true;
	}
	return -1;
}
public Native_SetDonatorMessage(Handle:plugin, params)
{
	decl String:szSteamId[64], String:szNewTag[256];
	GetClientAuthString(GetNativeCell(1), szSteamId, sizeof(szSteamId));
	
	GetNativeString(2, szNewTag, sizeof(szNewTag));
	SetTrieString(g_hDonatorTagTrie, szSteamId, szNewTag);
	SetClientCookie(GetNativeCell(1), g_CookieTag, szNewTag);
	return true;
}
public Forward_OnDonatorConnect(iClient)
{
	new bool:result;
	Call_StartForward(g_hForward_OnDonatorConnect);
	Call_PushCell(iClient);
	Call_Finish(_:result);
	return result;
}
public Forward_OnPostDonatorCheck(iClient)
{
	new bool:result;
	Call_StartForward(g_hForward_OnPostDonatorCheck);
	Call_PushCell(iClient);
	Call_Finish(_:result);
	return result;
}