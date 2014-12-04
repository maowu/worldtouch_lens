void receive( byte[] data, String ip, int port ) {  // <-- extended handler

  if (data.length>2) {
    data = subset(data, 0, data.length-1);
    String message = new String( data );

    String input = new String(data);
    if (input!="") {
      tdata = int(split(input, ','));

      if (tdata[0] == 255 && tdata[1] == 255) {
        //println("get interactive value");
        for (int i=2; i<tdata.length; i+=2) {
          RemoteLenVal_Arr[ tdata[i] ] = - tdata[i+1];
          int tmp_val = floor((RemoteLenVal_Arr[tdata[i]] + Len_Arr[tdata[i]].getVal() )/2);

          Len_Arr[tdata[i]].setVal(tmp_val);
        }
      } else if (tdata[0] == 255 && tdata[1] == 254) {
        client_center.clear();
        for (int i=2; i<tdata.length; i+=2) {
          //println(i+"_"+tdata[i]+","+tdata[i+1]);
          client_center.add(new PVector(tdata[i], tdata[i+1]));
        }
      }
    }
  }
}

void sendInteraction(ArrayList<PVector> pt) {
  String msg = "";
  msg = 255+ ","+ 254;
  for (int k = 0; k< pt.size (); k++) {
    PVector tmp_p = pt.get(k);
    fill(200, 100, 50, 100);
    ellipse(tmp_p.x, tmp_p.y, 100, 100);
    if (msg=="") {
      msg = floor(tmp_p.x)+ ","+floor(tmp_p.y) ;
    } else {
      msg = msg+ "," +floor(tmp_p.x)+ ","+floor(tmp_p.y) ;
    }
  }
  msg+="\n";
  udp.send( msg, HOST_IP, send_port );
}

void sendInteractionLen(int len, int val) {
  String msg = "";
  msg = 255+ ","+ 255; // for send interactive value
  if (msg=="") {
    msg = len+ ","+val ;
  } else {
    msg = msg+ "," +len+ ","+val ;
  }
  msg+="\n";
  udp.send( msg, HOST_IP, send_port );
}

void sendInteractionCursor(int x, int y) {
  String msg = "";
  msg = 255+ ","+ 254; // for send interactive value
  if (msg=="") {
    msg = x+ ","+y ;
  } else {
    msg = msg+ "," +x+ ","+y ;
  }
  msg+="\n";
  udp.send( msg, HOST_IP, send_port );
}

void drawClientInteractive(ArrayList<PVector> pt) {
  //println(pt.size());
  for (int k = 0; k< pt.size (); k++) {
    PVector tmp_p = pt.get(k);
    fill(50, 100, 200, 100);
    noStroke();
    ellipse(tmp_p.x, tmp_p.y, 100, 100);
  }
}

