package com.csoft.clinelympics;

import java.util.Date;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Score {
	private String playerID;
	private int gameID;
	private int playerScore;
	private Key scoreKey;
	
	public static final String keyName = "scoreList";
	public static final String keyKind = "Scores";
	public static final String entityKind = "score";

	public Score() {
		scoreKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public Score(String pID, int gID, int pScore) {
		scoreKey = KeyFactory.createKey(keyKind, keyName);
		playerID = pID;
		gameID = gID;
		playerScore = pScore;
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
		score.setProperty("playerID", playerID);
		score.setProperty("gameID", gameID);
		score.setProperty("playerScore", playerScore);
		score.setProperty("date", new Date());
		
		return score;
	}
}
