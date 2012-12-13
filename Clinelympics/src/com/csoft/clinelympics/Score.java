package com.csoft.clinelympics;

import java.util.Date;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Score {
	private String playerID;
	private int gameID;
	private int playerScore;
	private int eventID;
	private Key scoreKey;
	
	public static final String keyName = "scoreList";
	public static final String keyKind = "Scores";
	public static final String entityKind = "score";
	public static final String playerIDName = "playerID";
	public static final String gameIDName = "gameID";
	public static final String eventIDName = "eventID";
	public static final String playerScoreName = "playerScore";
	public static final String dateName = "date";

	public Score() {
		scoreKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public Score(String pID, int gID, int pScore, int eID) {
		scoreKey = KeyFactory.createKey(keyKind, keyName);
		eventID = eID;
		playerID = pID;
		gameID = gID;
		playerScore = pScore;
	}
	
	public Score(Entity eScore) {
		scoreKey = KeyFactory.createKey(keyKind, keyName);
		eventID = ((Long) eScore.getProperty(eventIDName)).intValue();
		playerID = (String) eScore.getProperty(playerIDName);
		gameID = ((Long) eScore.getProperty(gameIDName)).intValue();
		playerScore = ((Long) eScore.getProperty(playerScoreName)).intValue();
	}

	public void setPlayerID(String playerID) {
		this.playerID = playerID;
	}

	public String getPlayerID() {
		return playerID;
	}

	public void setGameID(int gameID) {
		this.gameID = gameID;
	}

	public int getGameID() {
		return gameID;
	}

	public void setPlayerScore(int playerScore) {
		this.playerScore = playerScore;
	}

	public int getPlayerScore() {
		return playerScore;
	}
	
	public Entity createEntity() {
		Entity score = new Entity(entityKind, scoreKey);
		score.setProperty(eventIDName, eventID);
		score.setProperty(playerIDName, playerID);
		score.setProperty(gameIDName, gameID);
		score.setProperty(playerScoreName, playerScore);
		score.setProperty(dateName, new Date());
		
		return score;
	}
	
	public boolean equals(Score a) {
		if (a.getPlayerID().equals(this.playerID) &&
				(a.getGameID() == this.gameID) &&
				(a.getPlayerScore() == this.playerScore) &&
				(a.getEventID() == this.eventID)) {
			return true;
		}
		return false;
	}

	public Key getScoreKey() {
		return scoreKey;
	}

	public void setEventID(int eventID) {
		this.eventID = eventID;
	}

	public int getEventID() {
		return eventID;
	}
}
