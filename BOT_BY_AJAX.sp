#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
int rocket = INVALID_ENT_REFERENCE;
int bot;
int g_VotesPvB[MAXPLAYERS+1];
bool attack = false;
bool enable= false;
int distance = 250;
int critical_distance = 50;
int move_distance = 300;
int weapon = 0;
bool deflect_pause = true;
int target_close = 0;
int global_deflection = 0;
float random_angle = 180.0;
float global_angle[3];
bool choise_angle = false;
public void OnPluginStart(){
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	RegAdminCmd("sm_pvb", PVB_Cmd, ADMFLAG_CONVARS, "");
	RegConsoleCmd("sm_votepvb", VotePvB_Cmd, "", 0);
}
public void OnEntityCreated(int entity, const char[] classname){
	if (enable)
	{
		if (StrEqual(classname, "tf_projectile_rocket", false))
		{
			rocket = entity;
			global_deflection = 0;
		}
	}
}
public void OnEntityDestroyed(int entity){
	if (rocket == entity)
	{
		rocket = INVALID_ENT_REFERENCE
	}
}
public void OnGameFrame()
{
	if (enable)
	{
		attack = false;
		if (rocket != INVALID_ENT_REFERENCE)
		{
			float bot_position[3], rocket_position[3], bot_rocket[3], rocket_angle[3];
			int iDeflectionCount = GetEntProp(rocket, Prop_Send, "m_iDeflected");
			GetClientEyePosition(bot, bot_position);
			GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", rocket_position);
			GetEntPropVector(rocket, Prop_Data, "m_angRotation", rocket_angle);
			if (GetVectorDistance(bot_position, rocket_position) <= move_distance && GetEntProp(rocket, Prop_Send, "m_iTeamNum") != 2)
			{
				float angle[3];
				MakeVectorFromPoints(rocket_position, bot_position, bot_rocket);
				NormalizeVector(bot_rocket, bot_rocket);
				GetVectorAngles(bot_rocket, angle);
				AngleFix(angle);
				if (GetPlayerEye(rocket_position, rocket_angle) == bot || GetVectorDistance(bot_position, rocket_position) <= critical_distance
					|| (GetVectorDistance(bot_position, rocket_position) <= distance && GetViewAngleToTarget(bot, rocket) <= random_angle/2))
				{
					TeleportEntity(bot, NULL_VECTOR, angle, NULL_VECTOR);
					attack = true;
					ModRateOfFire(weapon);
					deflect_pause = false;
					if (!choise_angle)
					{
						global_angle[0] = angle[0];
						global_angle[1] = angle[1];
						global_angle[2] = angle[2];
					}
				}
				else
				{
					bot_rocket[2] = 0.0;	
					ScaleVector(bot_rocket, 5000.0);
					TeleportEntity(bot, NULL_VECTOR, NULL_VECTOR, bot_rocket);
				}
			}
			else
			{
				float angle[3], player_vec[3], bot_player[3];
				if (!IsValidClient(target_close, true))
				{
					target_close = GetRandomPlayer();
				}
				else
				{
					float delta[3], new_point[3];
					GetClientEyePosition(target_close, player_vec);
					MakeVectorFromPoints(player_vec, bot_position, bot_player);
					NormalizeVector(bot_player, bot_player);
					GetVectorAngles(bot_player, angle);
					AngleFix(angle);
					delta[0] = -1.0 * player_vec[0];
					delta[1] = -1.0 * player_vec[1];
					MakeVectorFromPoints(delta, bot_position, new_point);
					NormalizeVector(new_point, new_point);
					if (deflect_pause)
					{
						ScaleVector(new_point, -4000.0)
						new_point[2] = 0.0;
						TeleportEntity(bot, NULL_VECTOR, angle, new_point);
					}
					if (choise_angle)
					{
						choise_angle = false;
						global_angle[0] = angle[0];
						global_angle[1] = angle[1];
						global_angle[2] = angle[2];
					}
				}
			}
			if (!deflect_pause)
			{
				if (iDeflectionCount > global_deflection)
				{
					CreateTimer(0.1, ResetState);
					global_deflection = iDeflectionCount;
					if (GetRandomInt(1, 5) == 5)
					{
						choise_angle = true;
					}
					else
					{
						switch (GetRandomInt(1, 10)) 
						{
							case 1, 2, 3:
							{
								global_angle[0] += GetRandomFloat(-10.0, 10.0);
							}
							case 4, 5, 6:
							{
								global_angle[1] += GetRandomFloat(-15.0, 15.0);
							}
							case 7, 8:
							{
								global_angle[0] += GetRandomFloat(-45.0, 45.0);
							}
							case 9, 10:
							{
								global_angle[1] += GetRandomFloat(-90.0, 90.0);
							}
						}
					}
					if (global_angle[0] <= -90.0)
					{
						global_angle[0] = -89.0;
					}
					if (global_angle[0] >= 90.0)
					{
						global_angle[0] = 89.0;
					}
					if (global_angle[1] > 180.0)
					{
						global_angle[1] -= 360.0;
					}
					if (global_angle[1] < -180.0)
					{
						global_angle[1] += 360.0;
					}
					if (GetRandomInt(1, 3) == 3)
					{
						distance = 0;
						CreateTimer(2.5, ResetDistance);
					}
					else	
					{
						distance = GetRandomInt(200, 250);
					}
					random_angle = ((distance + 1.0)/2.0) + 45.0;
				}
				TeleportEntity(bot, NULL_VECTOR, global_angle, NULL_VECTOR);
			}
			int client = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
			if (client >= 1 && !IsFakeClient(client))
			{
				target_close = client;
			}
		}
	}
}
public int GetPlayerEye(float origin[3], float angle[3])
{
	int index = -1;  
	Handle trace = TR_TraceRayFilterEx(origin, angle, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		index = TR_GetEntityIndex(trace); 
	}
	CloseHandle(trace); 
	return index;
}
public bool TraceEntityFilterPlayer(entity, contentsMask) 
{ 
    return (1 <= entity <= MaxClients); 
}
public Action ResetState(Handle hTimer)
{
	deflect_pause = true;
	choise_angle = false;
}
public Action ResetDistance(Handle hTimer)
{
	distance = 285;
}
stock ModRateOfFire(weap)
{
	float m_flNextSecondaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 10.0);
	float fGameTime = GetGameTime();
	float fSecondaryTime = ((m_flNextSecondaryAttack - fGameTime) - 0.99);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", fSecondaryTime + fGameTime);
}
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (attack && IsFakeClient(iClient))	
	{
		iButtons |= IN_ATTACK2
	}
	return Plugin_Continue;
}
public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!enable)
	{
		DestroyBot();
	}
	else
	{
		if (IsClientBot(client))
		{
			bot = client;
			SetEntityGravity(client, 400.0);
			SetEntProp(bot, Prop_Data, "m_takedamage", 1, 1);
			ChangeClientTeam(client, 2);
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		}
		if (IsValidClient(client) && !IsFakeClient(client) &&  GetClientTeam(client) == 2)
		{
			ChangeClientTeam(client, 3);
		}
	}
}
stock bool IsClientBot(client)
{
	return client != 0 && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client);
}
public void OnClientDisconnect(int client)
{
	g_VotesPvB[client] = 0;
	if (GetRealClientCount() == 0)	
	{
		DisableMode();
	}
}
public Action PVB_Cmd(int client, args) 
{
	if(!enable)	
	{
		EnableMode();
	}
	else	
	{
		DisableMode();
	}
	return Plugin_Handled;
}
public Action VotePvB_Cmd(int client, args)
{
	if(g_VotesPvB[client] == 1) 
	{
		PrintToChat(client, "\x073EFF3E[Player vs. Bot]\x07ADD8E6 You have already voted.");
	}
	else 
	{
		if(!enable)
		{
			PrintToChatAll("\x073EFF3E[Player vs. Bot] \x0700FFFF%N\x01 wants to enable Player vs Bot. (\x07ADD8E6%d\x01 votes, \x07ADD8E6%d\x01 required)", client, GetPlayersVotedPvB() + 1, GetRealClientCount()/2 + 1);
		}
		else
		{
			PrintToChatAll("\x073EFF3E[Player vs. Bot] \x0700FFFF%N\x01 wants to disable Player vs Bot. (\x07ADD8E6%d\x01 votes, \x07ADD8E6%d\x01 required)", client, GetPlayersVotedPvB() + 1, GetRealClientCount()/2 + 1);
		}
		g_VotesPvB[client] = 1;
	}
	
	if(GetPlayersVotedPvB() == GetRealClientCount()/2 + 1) 
	{
		if(enable)	
		{
			DisableMode();
		}
		else	
		{
			EnableMode();
		}
		for(int i = 0; i < MaxClients; i++)
		{
			g_VotesPvB[i] = 0;
		}
	}
	return Plugin_Handled;
}
stock int GetRealClientCount()
{
	int real_player = 0;
	for (int i = 1; i <= MaxClients; i++)
	{	
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 3)) 
		{
			real_player++;
		}
	}
	return real_player;
}
stock int GetPlayersVotedPvB()
{
	int count = 0;
	for(int i = 0; i < MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i) && g_VotesPvB[i] == 1)	
		{
			count++;
		}		
	}
	return count;
}
stock bool IsValidClient(int iClient, bool bAlive = false)
{
	if (iClient >= 1 && iClient <= MaxClients && IsClientConnected(iClient) && IsClientInGame(iClient) && (bAlive == false || IsPlayerAlive(iClient)))
	{
		return true;
	}
	return false;
}
stock void EnableMode()
{
	DestroyBot();
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("tf_bot_add 1 Pyro red easy \"Oracle BOT\"");
	ServerCommand("tf_bot_difficulty 0");
	ServerCommand("tf_bot_keep_class_after_death 1");
	ServerCommand("tf_bot_taunt_victim_chance 0");
	ServerCommand("tf_bot_join_after_player 0");
	rocket = INVALID_ENT_REFERENCE;
	for(int i = 1; i < MaxClients; i++)	
	{
		if(IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)	
		{
			ChangeClientTeam(i, 3);
		}
	}
	PrintToChatAll("\x073EFF3E[Player vs. Bot]\x07ADD8E6 Mode Enable.");
	ServerCommand("sm_bot_mod 1");
	enable = true;
}
stock void DisableMode(){
	enable = false;
	rocket = INVALID_ENT_REFERENCE;
	DestroyBot();
	BalanceTeams();
	PrintToChatAll("\x073EFF3E[Player vs. Bot]\x07ADD8E6 Mode Disable.");
	ServerCommand("sm_bot_mod 0");
}
stock void BalanceTeams()
{
	int RandomPlayer;
	int Successfully = GetTeamClientCount(3)/2;
	while(Successfully != 0) 
	{
		RandomPlayer = GetRandomInt(1, MaxClients);
		if (IsValidClient(RandomPlayer) && GetClientTeam(RandomPlayer) == 3)
		{
			ChangeClientTeam(RandomPlayer, 2);
			Successfully -= 1;
		}
	}
}
stock void DestroyBot()
{	
	ServerCommand("tf_bot_kick all");
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("bot");
	CreateNative("GetBotStatus", Native_Get_Status);
	return APLRes_Success;
}
public Native_Get_Status(Handle:plugin,numParams)
{
	return enable;
}
stock void AngleFix(float Angle[3])
{
	Angle[0] *= -1.0;
	if(Angle[0] > 270)	
	{
		Angle[0]-=360;
	}
	if (Angle[0] < -180.0)	
	{
		Angle[0] += 360.0
	}
	Angle[1] += 180.0;
}
stock int GetRandomPlayer()
{
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
        {
            clients[clientCount++] = i;
        }
    }
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
stock float GetViewAngleToTarget(int client, int target)
{
	float clientpos[3], targetpos[3], anglevector[3], targetvector[3], resultangle;
	GetClientEyeAngles(client, anglevector);		anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	GetClientAbsOrigin(client, clientpos);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetpos);		clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	return resultangle;
}