package com.csoft.clinelympics;

import java.util.Date;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Text {
	private String smsID;
	private String accountSID;
	private String from;
	private String body;
	private Date sentDate;
	private Key textKey;
	
	public static final String KEY_NAME = "textList";
	public static final String KEY_KIND = "Texts";
	public static final String ENTITY_KIND = "text";
	public static final String SMS_SID = "SmsSid";
	public static final String ACCOUNT_SID = "AccountSid";
	public static final String FROM = "From";
	public static final String BODY = "Body";
	public static final String SENT_DATE = "date";

	public Text() {
		setTextKey(KeyFactory.createKey(KEY_KIND, KEY_NAME));
	}
	
	public Text(String sID, String aID, String f, String b) {
		setTextKey(KeyFactory.createKey(KEY_KIND, KEY_NAME));
		setSmsID(sID);
		setAccountSID(aID);
		setFrom(f);
		setBody(b);
		setSentDate(new Date());
	}
	
	public Text(Entity eText) {
		setTextKey(KeyFactory.createKey(KEY_KIND, KEY_NAME));
		setSmsID((String) eText.getProperty(SMS_SID));
		setAccountSID((String) eText.getProperty(ACCOUNT_SID));
		setFrom((String) eText.getProperty(FROM));
		setBody((String) eText.getProperty(BODY));
		setSentDate((Date) eText.getProperty(SENT_DATE));
	}

	public void setSmsID(String smsID) {
		this.smsID = smsID;
	}

	public String getSmsID() {
		return smsID;
	}

	public void setAccountSID(String accountSID) {
		this.accountSID = accountSID;
	}

	public String getAccountSID() {
		return accountSID;
	}

	public void setFrom(String from) {
		this.from = from;
	}

	public String getFrom() {
		return from;
	}

	public void setBody(String body) {
		this.body = body;
	}

	public String getBody() {
		return body;
	}

	public void setSentDate(Date sentDate) {
		this.sentDate = sentDate;
	}

	public Date getSentDate() {
		return sentDate;
	}

	public void setTextKey(Key textKey) {
		this.textKey = textKey;
	}

	public Key getTextKey() {
		return textKey;
	}
	
	public Entity createEntity() {
		Entity text = new Entity(ENTITY_KIND, textKey);
		text.setProperty(SMS_SID, smsID);
		text.setProperty(ACCOUNT_SID, accountSID);
		text.setProperty(FROM, from);
		text.setProperty(BODY, body);
		text.setProperty(SENT_DATE, sentDate);
		
		return text;
	}
}
