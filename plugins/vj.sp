#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <bot>

new Handle:g_hCvarUnbalanceLimit;
new Handle:g_hTimerJuggernautHud;
new Handle:g_hHudSynchronizer;

new g_iJuggernaut;
new g_iDamage						[MAXPLAYERS + 1];
new bool:g_bVotedForJuggernaut		[MAXPLAYERS + 1];
int oldJuggernaut;
bool JuggernautSatus;
bool JuggernautRoundStart;
public OnPluginStart()
{
	g_hCvarUnbalanceLimit = FindConVar("mp_teams_unbalance_limit");
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_setup_finished", OnArenaStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	RegAdminCmd("sm_fj", JuggernautCmd, ADMFLAG_GENERIC);
	RegAdminCmd("sm_vj", VoteJuggernautCmd, 0);
	g_hHudSynchronizer = CreateHudSynchronizer();
}
public OnMapStart()
{
	JuggernautSatus = false;
	JuggernautRoundStart = false;
	g_iJuggernaut = 0;
}

public OnClientConnected(iClient)
{
	g_iDamage[iClient] = 0;
	g_bVotedForJuggernaut[iClient] = false;
}

public OnClientDisconnect_Post(iClient)
{
	if(iClient == g_iJuggernaut)
	{
		g_iJuggernaut = 0;
		JuggernautRoundStart = false;
		ServerCommand("mp_scrambleteams");
	}
	g_bVotedForJuggernaut[iClient] = false;
	if(!JuggernautSatus)
	{
		new iVoteCount = GetJuggernautVoteCount();
		new iRatio = RoundToNearest((GetValidTeamClientCount(2) + GetValidTeamClientCount(3)) * 0.6);
		if(iVoteCount >= iRatio && iVoteCount >= 3)
		{
			JuggernautSatus = true;
			PrintToChatAll("\x073EFF3E[1 vs. All]\x07ADD8E6 In the next round enable.");
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
			g_bVotedForJuggernaut[iClient] = false;
		}
	}
}
public Action:OnRoundStart(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimerJuggernautHud);
	if(JuggernautSatus)
	{
		if (GetBotStatus())	return;
		new iNextJuggernaut = GetRandomPlayer();
		if(IsValidClient(iNextJuggernaut))
		{
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
			{
				if(GetClientTeam(i) > 1)
				{
					if(i != iNextJuggernaut)
					SetClientTeam(i, 3);
					else
					SetClientTeam(i, 2);
				}
			}
			JuggernautRoundStart = true;
			JuggernautSatus = false;
			g_iJuggernaut = iNextJuggernaut;
			PrintToChatAll("\x073EFF3E[1 vs. All] \x0700FFFF%N\x01 champion.", g_iJuggernaut);
			SetConVarInt(g_hCvarUnbalanceLimit, 0);
		}
	}
	else
	SetConVarInt(g_hCvarUnbalanceLimit, 3);
}
public Action:OnArenaStart(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	g_hTimerJuggernautHud = CreateTimer(1.0, Timer_JuggernautHud, _, TIMER_REPEAT);
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) > 1 && i == g_iJuggernaut)
			SetEntityHealth(i, 801 * GetValidTeamClientCount(3));
	}
}
public Action:OnPlayerHurt(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iVictim) || !IsValidClient(iAttacker))
		return;
	if(iVictim == g_iJuggernaut && iAttacker != g_iJuggernaut)
	g_iDamage[iAttacker] += GetEventInt(hEvent, "damageamount");
}
public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (JuggernautRoundStart)
	{
		int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (client == g_iJuggernaut && GetClientTeam(client) == 3)
		{
			SetClientTeam(client, 2);
		}
		if(GetClientTeam(client) == 2 && client != g_iJuggernaut )
		{
			SetClientTeam(client, 3);
		}
	}
}
public Action:OnRoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimerJuggernautHud);
	JuggernautRoundStart = false;
	if(!IsValidClient(g_iJuggernaut))
	return;
	g_iJuggernaut = 0;
	ServerCommand("mp_scrambleteams");
	if (GetRandomFloat(0.0, 100.0) > 90.0)
	{
		ServerCommand("sm_fj");
	}
}
public Action:JuggernautCmd(iClient, iArgs)
{
	if(!JuggernautSatus){
		JuggernautSatus = true;
		PrintToChatAll("\x073EFF3E[1 vs. All]\x07ADD8E6 In the next round enable.");
	}
	else{
		JuggernautSatus = false;
		PrintToChatAll("\x073EFF3E[1 vs. All]\x07ADD8E6 In the next round disable.");
	}
	return Plugin_Handled;
}

public Action:VoteJuggernautCmd(iClient, iArgs)
{
	if(JuggernautSatus)
	{
		PrintToChat(iClient, "\x073EFF3E[1 vs. All]\x07ADD8E6 In the next round enable.");
		return Plugin_Handled;
	}
	if(!g_bVotedForJuggernaut[iClient])
	{
		g_bVotedForJuggernaut[iClient] = true;
		new iVoteCount = GetJuggernautVoteCount();
		new iRatio = RoundToNearest((GetValidTeamClientCount(2) + GetValidTeamClientCount(3)) * 0.6);
		if(iRatio < 3)
		iRatio = 3;
		PrintToChatAll("\x073EFF3E[1 vs. All] \x0700FFFF%N\x01 wants to enable mode. (%d votes, %d required)", iClient, iVoteCount, iRatio);
		if(iVoteCount >= iRatio)
		{
			JuggernautSatus = true;
			PrintToChatAll("\x073EFF3E[1 vs. All]\x07ADD8E6 In the next round enable.");
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
			g_bVotedForJuggernaut[i] = false;
		}
	}
	else
		PrintToChat(iClient, "\x073EFF3E[1 vs. All]\x07ADD8E6 You have already voted.");
	return Plugin_Handled;
}
public Action:Timer_JuggernautHud(Handle:hTimer)
{
	if(!IsValidClient(g_iJuggernaut) || g_hHudSynchronizer == INVALID_HANDLE)
		return;
	SetHudTextParams(0.02, 0.02, 1.0, 255, 255, 255, 255);
	for(new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			ShowSyncHudText(i, g_hHudSynchronizer, "%Juggernaut HP: %i", GetClientHealth(g_iJuggernaut));
}
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
	return false;
	return true;
}

stock GetJuggernautVoteCount()
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(g_bVotedForJuggernaut[i])
		iCount++;
	}
	return iCount;
}

stock GetValidTeamClientCount(iTeam)
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) == iTeam)
		iCount++;
	}
	return iCount;
}
stock GetRandomPlayer()
{
	new iPlayers[MAXPLAYERS + 1];
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) > 1)
			iPlayers[iCount++] = i;
	}
	new RandomPlayer;
	do
	{
		RandomPlayer = iPlayers[GetRandomInt(0, iCount - 1)];
	} while (oldJuggernaut == RandomPlayer);
	oldJuggernaut = RandomPlayer;
	return RandomPlayer;
}
stock ResetAllTime()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		oldJuggernaut[i] = false;
	}
}
stock ClearTimer(&Handle:hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}
stock SetClientTeam(iClient, iTeam)
{
	SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(iClient, iTeam);
	TF2_RespawnPlayer(iClient);
}