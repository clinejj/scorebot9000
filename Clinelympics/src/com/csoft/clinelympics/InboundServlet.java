package com.csoft.clinelympics;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Random;

import javax.servlet.http.*;
import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.FetchOptions;
import com.google.appengine.api.datastore.Query;
import com.google.appengine.api.datastore.Query.Filter;
import com.google.appengine.api.datastore.Query.FilterPredicate;
import com.google.appengine.api.datastore.Query.FilterOperator;

import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import org.w3c.dom.*;

@SuppressWarnings("serial")
public class InboundServlet extends HttpServlet {
	
	private static final String cmdReg = "REGISTER";
	private static final String cmdScore = "SCORE";
	private static final String cmdWho = "WHO";
	private static final String cmdHelp = "HELP";
    
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		boolean isValid = true;
		String smsresp = "";
		Text inText = new Text(req.getParameter(Text.smsIDName), 
				req.getParameter(Text.accountSIDName), 
				req.getParameter(Text.fromName), 
				req.getParameter(Text.bodyName));
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		
		datastore.put(inText.createEntity());
		
		String[] split = inText.getBody().split(" ");
		if (split[0].equalsIgnoreCase(cmdReg)) {
			if (split.length >= 2) {
				String teamName = inText.getBody().substring(inText.getBody().indexOf(" ")+1).trim().toUpperCase();
				Random r = new Random(System.currentTimeMillis());
				Query query = new Query(Name.entityKind, new Name().getNameKey());
				
				if (r.nextInt() > 0) {
					query.addSort(Name.rndStr, Query.SortDirection.ASCENDING);
				} else {
					query.addSort(Name.rndStr, Query.SortDirection.DESCENDING);
				}
				Filter notUsed = new FilterPredicate(Name.usedStr, FilterOperator.EQUAL, false);
			    query.setFilter(notUsed);
			    List<com.google.appengine.api.datastore.Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(10));
			    int curEnt = r.nextInt(names.size());
			    String newName = (String) names.get(curEnt).getProperty(Name.nameStr);
			    
				Player player = new Player(inText.getFrom(), newName, teamName);
				datastore.put(player.createEntity());
				names.get(curEnt).setProperty(Name.usedStr, true);
				datastore.put(names.get(curEnt));
				
				smsresp = "Welcome to team " + teamName + ", "  + newName;
			} else {
				isValid = false;
			}
		} else if (split[0].equalsIgnoreCase(cmdScore)) {
			if (split.length == 3) {
				Score score = new Score(inText.getFrom(), Integer.parseInt(split[1]), Integer.parseInt(split[2]));
				datastore.put(score.createEntity());
			} else {
				isValid = false;
			}
		} else if (split[0].equalsIgnoreCase(cmdWho)) {
			// return player name
		} else if (split[0].equalsIgnoreCase(cmdHelp)) {
			isValid = true;
			smsresp = "Available commands: " + cmdReg + ", " + cmdScore + ", " + cmdWho + ", " + cmdHelp;
		} else {
			isValid = false;
		}
		
		if (!isValid) {
			smsresp = "I didn't understand. Text HELP for a list of available commands.";
		}
		
		resp.setContentType("text/xml");
		resp.setCharacterEncoding("UTF-8");
		PrintWriter sos = resp.getWriter();
		
		Document dom;
	    DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
	    try {
	        DocumentBuilder db = dbf.newDocumentBuilder();
	        dom = db.newDocument();

	        Element rootEle = dom.createElement("Response");
	        
			if (!smsresp.equals("")) {
		        Element e = dom.createElement("Sms");
		        e.appendChild(dom.createTextNode(smsresp));
		        rootEle.appendChild(e);
			}

	        dom.appendChild(rootEle);

	        try {
	            Transformer tr = TransformerFactory.newInstance().newTransformer();
	            tr.setOutputProperty(OutputKeys.INDENT, "yes");
	            tr.setOutputProperty(OutputKeys.METHOD, "xml");
	            tr.setOutputProperty(OutputKeys.ENCODING, "UTF-8");

	            tr.transform(new DOMSource(dom), 
	                                 new StreamResult(sos));

	        } catch (TransformerException te) {
	            System.out.println(te.getMessage());
	        }
	    } catch (ParserConfigurationException pce) {
	        System.out.println(pce.getMessage());
	    }
	}
}
