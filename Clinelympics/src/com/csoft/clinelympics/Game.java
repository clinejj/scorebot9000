package com.csoft.clinelympics;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Game {
	private int gameID;
	private String gameName;
	private boolean scoreType;	// True = high score
	private int eventID;
	private Key gameKey;
	
	public static final String keyName = "gameList";
	public static final String keyKind = "Games";
	public static final String entityKind = "game";
	public static final String gameIDName = "gameID";
	public static final String gameNameName = "gameName";
	public static final String scoreTypeName = "scoreType";
	public static final String eventIDName = "eventID";
	
	public Game() {
		gameKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public Game(int gID, String gName, boolean sType, int eID) {
		gameKey = KeyFactory.createKey(keyKind, keyName);
		gameID = gID;
		gameName = gName;
		scoreType = sType;
		eventID = eID;
	}
	
	public Game(Entity eGame) {
		gameKey = KeyFactory.createKey(keyKind, keyName);
		gameID = ((Long) eGame.getProperty(gameIDName)).intValue();
		gameName = (String) eGame.getProperty(gameNameName);
		scoreType = (Boolean) eGame.getProperty(scoreTypeName);
		eventID = ((Long) eGame.getProperty(eventIDName)).intValue();
	}
	
	public void setGameID(int gameID) {
		this.gameID = gameID;
	}
	
	public int getGameID() {
		return gameID;
	}
	
	public void setGameName(String gameName) {
		this.gameName = gameName;
	}
	
	public String getGameName() {
		return gameName;
	}
	
	public void setScoreType(boolean scoreType) {
		this.scoreType = scoreType;
	}
	
	public boolean isScoreType() {
		return scoreType;
	}
	
	public Entity createEntity() {
		Entity game = new Entity(entityKind, gameKey);
		game.setProperty(gameIDName, gameID);
		game.setProperty(gameNameName, gameName);
		game.setProperty(scoreTypeName, scoreType);
		game.setProperty(eventIDName, eventID);
		
		return game;
	}

	public Key getGameKey() {
		return gameKey;
	}

	public void setEventID(int eventID) {
		this.eventID = eventID;
	}

	public int getEventID() {
		return eventID;
	}
}
