#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define PLUGIN_VERSION "1.0.15"
public OnMapStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_StartTouch, OnStartTouch);
}
public Action:OnStartTouch(client, other)
{
	if(other > 0 && other <= MaxClients)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			decl Float:ClientPos[3];
			decl Float:VictimPos[3];
			decl Float:VictimVecMaxs[3];
			GetClientAbsOrigin(client, ClientPos);
			GetClientAbsOrigin(other, VictimPos);
			GetEntPropVector(other, Prop_Send, "m_vecMaxs", VictimVecMaxs);
			new Float:victimHeight = VictimVecMaxs[2];
			new Float:HeightDiff = ClientPos[2] - VictimPos[2];

			if(HeightDiff > victimHeight)
			{
				decl Float:vec[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

				if(vec[2] < 360 * -1.0)
				{
					if(Goomba_SingleStomp[client] == 0)
					{
						if(AreValidStompTargets(client, other))
						{
							new immunityResult = CheckStompImmunity(client, other);

							if(immunityResult == GOOMBA_IMMUNFLAG_NONE)
							{
								if(GoombaStomp(client, other))
								{
									PlayStompReboundSound(client);
									EmitStompParticles(other);
								}
								Goomba_SingleStomp[client] = 1;
								CreateTimer(0.5, SinglStompTimer, client);
							}
							else if(immunityResult & GOOMBA_IMMUNFLAG_VICTIM)
							{
								CPrintToChat(client, "%t", "Victim Immun");
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

}