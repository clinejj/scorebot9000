package com.csoft.clinelympics;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Player {
	private String playerID;
	private String playerName;
	private String teamName;
	private Key playerKey;
	
	public static final String keyName = "playerList";
	public static final String keyKind = "Players";
	public static final String entityKind = "player";
	
	public Player() {
		playerKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public Player(String pID, String pName, String tName) {
		playerKey = KeyFactory.createKey(keyKind, keyName);
		playerID = pID;
		playerName = pName;
		teamName = tName;
	}
	
	public void setPlayerID(String playerID) {
		this.playerID = playerID;
	}
	public String getPlayerID() {
		return playerID;
	}
	public void setPlayerName(String playerName) {
		this.playerName = playerName;
	}
	public String getPlayerName() {
		return playerName;
	}
	public void setTeamName(String teamName) {
		this.teamName = teamName;
	}
	public String getTeamName() {
		return teamName;
	}
	
	public Entity createEntity() {
		Entity player = new Entity(entityKind, playerKey);
		player.setProperty("playerID", playerID);
		player.setProperty("playerName", playerName);
		player.setProperty("teamName", teamName);
		
		return player;
	}
}
