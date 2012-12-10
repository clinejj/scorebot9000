package com.csoft.clinelympics;

import java.util.ArrayList;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Player {
	private String playerID;
	private String playerName;
	private String teamName;
	private Key playerKey;
	private ArrayList<Score> scores;
	
	public static final String keyName = "playerList";
	public static final String keyKind = "Players";
	public static final String entityKind = "player";
	
	public Player() {
		playerKey = KeyFactory.createKey(keyKind, keyName);
		scores = new ArrayList<Score>();
	}
	
	public Player(String pID, String pName, String tName) {
		playerKey = KeyFactory.createKey(keyKind, keyName);
		playerID = pID;
		playerName = pName;
		teamName = tName;
		scores = new ArrayList<Score>();
	}
	
	public Player(Entity pA) {
		playerID = (String) pA.getProperty("playerID");
		playerName = (String) pA.getProperty("playerName");
		teamName = (String) pA.getProperty("teamName");
		playerKey = KeyFactory.createKey(keyKind, keyName);
		scores = new ArrayList<Score>();
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
	
	public void addScore(Score newScore) {
		scores.add(newScore);
	}
	
	public void removeScore(Score newScore) {
		scores.remove(newScore);
	}
	
	public ArrayList<Score> getScores() {
		return scores;
	}
	
	public Entity createEntity() {
		Entity player = new Entity(entityKind, playerKey);
		player.setProperty("playerID", playerID);
		player.setProperty("playerName", playerName);
		player.setProperty("teamName", teamName);
		
		return player;
	}
}
