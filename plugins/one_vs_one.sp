#include <sourcemod>
#include <sdkhooks>
public void OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}
public Action OnClientTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	damage = 0.0;
	return Plugin_Changed;
}
stock bool GetPlayerTeam()
{
	bool red = false, blue = false;
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == 3)
			{
				blue = true;
				count++;
			}
			if (GetClientTeam(i) == 2)
			{
				red = true;
				count++;
			}
		}
	}
	return (blue && red && count == 2) ? true : false;
}
stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}
