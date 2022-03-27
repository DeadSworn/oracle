#include <sourcemod>
#include <sdktools> 
#include <sdkhooks>
#include <tf2_stocks>
public void OnPluginStart()
{
	RegConsoleCmd("sm_dodgeball_turnrate", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_weaponparticle", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_enabled", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_criticals", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_spawninterval", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_reflectinc", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_speedmul", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_maxrockets", CommandOctagon);
	RegConsoleCmd("sm_dodgeball_basedamage", CommandOctagon);
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	ServerCommand("sm_cvar nb_blind 1");
	ServerCommand("sm_cvar tf_flamethrower_burstammo 0");
	ServerCommand("sm_cvar tf_avoidteammates_pushaway 0");
	PrintToChatAll("Reload DB_Util");
}
public Action Event_Death(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	char weapon[16];
	GetEventString(hEvent, "weapon", weapon, sizeof(weapon));
	if (StrEqual(weapon, "env_explosion"))
	{
		int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		if (victim != attacker)
		{
			SetEventString(hEvent, "weapon", "deflect_rocket");
			SetEventInt(hEvent, "damagebits", DMG_CRIT);
			SetEventInt(hEvent, "weaponid", 22);
		}
		else
		{
			SetEventString(hEvent, "weapon", "tf_pumpkin_bomb");
			SetEventInt(hEvent, "damagebits", (GetEventInt(hEvent, "damagebits") & DMG_CRIT) | DMG_BLAST);
			SetEventInt(hEvent, "customkill", TF_CUSTOM_PUMPKIN_BOMB);
		}
	}
	return Plugin_Continue;
}
public Action CommandOctagon(int client, args)
{
	return Plugin_Handled;
}