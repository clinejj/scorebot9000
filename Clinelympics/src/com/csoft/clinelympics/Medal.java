package com.csoft.clinelympics;

import java.util.ArrayList;
import java.util.HashMap;

public class Medal {
	private HashMap<String, MedalScore> scores;
	private ArrayList<String> medalNames;
	private boolean scoreType; // True = high score wins
	
	public static final String BRONZE = "bronze";
	public static final String SILVER = "silver";
	public static final String GOLD = "gold";
	public static final int TOTAL_MEDALS = 3;
	
	public Medal() {
		scores = new HashMap<String, MedalScore>();
		medalNames = new ArrayList<String>();
		setScoreType(true);
		zeroScores();
		setMedalNames();
	}
	
	private void setMedalNames() {
		medalNames.add("Gold");
		medalNames.add("Silver");
		medalNames.add("Bronze");
	}

	public Medal(boolean t) {
		scores = new HashMap<String,MedalScore>();
		medalNames = new ArrayList<String>();
		setScoreType(t);
		zeroScores();
		setMedalNames();
	}
	
	public void addScore(MedalScore s) {
		if (s.score == scores.get(GOLD).score) {
			s.displayName = s.displayName + ", " + scores.get(GOLD).displayName;
			scores.put(GOLD, s);
		} else if (s.score == scores.get(SILVER).score) {
			s.displayName = s.displayName + ", " + scores.get(SILVER).displayName;
			scores.put(SILVER, s);
		} else if (s.score == scores.get(BRONZE).score) {
			s.displayName = s.displayName + ", " + scores.get(BRONZE).displayName;
			scores.put(BRONZE, s);
		} else {	
			if (scoreType) {
				if (s.score > scores.get(GOLD).score) {
					scores.put(BRONZE, scores.get(SILVER));
					scores.put(SILVER, scores.get(GOLD));
					scores.put(GOLD, s);
				} else if ((s.score < scores.get(GOLD).score) && (s.score > scores.get(SILVER).score)) {
					scores.put(BRONZE, scores.get(SILVER));
					scores.put(SILVER, s);
				} else if ((s.score < scores.get(SILVER).score) && (s.score > scores.get(BRONZE).score)) {
					scores.put(BRONZE, s);
				}
			} else {
				if (s.score < scores.get(GOLD).score) {
					scores.put(BRONZE, scores.get(SILVER));
					scores.put(SILVER, scores.get(GOLD));
					scores.put(GOLD, s);
				} else if ((s.score > scores.get(GOLD).score) && (s.score < scores.get(SILVER).score)) {
					scores.put(BRONZE, scores.get(SILVER));
					scores.put(SILVER, s);
				} else if ((s.score > scores.get(SILVER).score) && (s.score < scores.get(BRONZE).score)) {
					scores.put(BRONZE, s);
				}
			}
		}
	}
	
	public void addScore(String type, MedalScore s) {
		if (isValidType(type)) {
			if (s.score > scores.get(type).score) {
				scores.put(type, s);
			} else if (s.score == scores.get(type).score) {
				s.displayName = s.displayName + ", " + scores.get(type).displayName;
				scores.put(type, s);
			}
		}
	}
	
	public void addScore(String n, int s) {
		MedalScore m = new MedalScore(n, s);
		addScore(m);
	}
	
	public void addScore(String type, String name, int score) {
		MedalScore m = new MedalScore(name, score);
		addScore(type, m);
	}
	
	public MedalScore getScore(String type) {
		if (isValidType(type)) {
			return scores.get(type);
		} else {
			return null;
		}
	}
	
	public boolean isValidType(String type) {
		type = type.toLowerCase();
		if (type.equals(BRONZE)) {
			return true;
		} else if (type.equals(SILVER)) {
			return true;
		} else if (type.equals(GOLD)) {
			return true;
		} else {
			return false;
		}
	}

	public void setScoreType(boolean scoreType) {
		this.scoreType = scoreType;
	}

	public boolean getScoreType() {
		return scoreType;
	}
	
	private void zeroScores() {
		MedalScore s = new MedalScore("", Integer.MIN_VALUE);
		if (scoreType) {
			scores.put(BRONZE, s);
			scores.put(SILVER, s);
			scores.put(GOLD, s);
		} else {
			s.score = Integer.MAX_VALUE;
			scores.put(BRONZE, s);
			scores.put(SILVER, s);
			scores.put(GOLD, s);
		}
	}

	public void setMedalNames(ArrayList<String> medalNames) {
		this.medalNames = medalNames;
	}

	public ArrayList<String> getMedalNames() {
		return medalNames;
	}
}
