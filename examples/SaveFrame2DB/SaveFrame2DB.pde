import java.io.*; //<>//
import java.nio.*;
import java.sql.Statement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLSyntaxErrorException;  
import java.sql.PreparedStatement;
import java.util.*;
import java.sql.ResultSet;

//If the import below throws an error, create under your sketch
//directory a subdirectory named "code" and copy there the
//derby jars of your javadb installation.
import org.apache.derby.drda.NetworkServerControl;

static NetworkServerControl server;
PreparedStatement ps;
Connection conn;
Statement stmt;
ResultSet rset;

// String dirResources;
PImage frame;
String title;
int initialX=50;
int initialY=30;
int countFrames=0;
int frameWidth=100;
int frameHeight=100;
int x = 0;

void setup() {
  size(800, 800);
  // Databases will be allocated under "./sketchPath/databases".
  // Derby allocates each database in a separate directory.
  System.setProperty("derby.system.home", sketchPath("databases"));
  println("sketchPath: " + sketchPath("databases"));

  try {
    // We initialize the DB to access online mode.
    startServer();

    openDBbyServer("MyFramesDB"); // If no exist the DB, it is created.
    createBlobsTable();          // Here is created the blobs table.
    prepareInsert();        // The preparedStatement clause.
  } 
  catch (Exception e ) {
    e.printStackTrace();
  }
}

void draw() {
  textSize(24);
  if (x < 100) {        // Saving frames
    background(204);
    rect(initialX, initialY, frameWidth, frameHeight);
    line(x + initialX, initialY, x + initialX, frameHeight + initialY);
    text("Saving frames into the database...", 200, initialY + 50);
    text("Frame = " + (x+1), 200, initialY + 80);
   
    // At the end of each cycle we save the frame into the DB.
    frame = get(initialX, initialY, frameWidth, frameHeight);
    //image(frame, (countFrames % 8) * 100, 0);
    countFrames++;
    saveFrame2DB(frame);
    x++;
  } else {            // Dislaying savedd frames

    noLoop();
    text("Reading the first twenty", 250, initialY + 130);

    try {
      stmt = conn.createStatement();
      String sql = "SELECT * from FRAMEBLOBS FETCH FIRST 20 ROWS ONLY";
      ResultSet rs = stmt.executeQuery(sql);

      textSize(24);

      int counter = 0, counter2 = 0;
      int gap = 10;

      while (rs.next()) {
        title = rs .getString("TITLE");
        text(title, initialX + counter*150, initialY + 170 + counter2 * 150);

        frame.pixels = bytes2Ints(rs.getBytes("IMAGE"));
        frame.updatePixels();

        image(frame, initialX + counter*150, initialY + 180 + counter2 * 150, frameWidth, frameHeight);
        // initialX + counter*150 + frameWidth, initialY + 150 + counter2 * 150 + frameHeight);

        counter++;
        if (counter >= 5) {
          counter = 0;
          counter2++;
        }
      }
    }
    catch (Exception e ) {
      e.printStackTrace();
      //image(frame, (countFrames % 8) * 100, 0);
    }
    finally 
    {
      try
      {
        if (stmt != null)
        {
          stmt.close();
        }
        closeDBbyServer(); //It is necesary to unlock the DB.
      }
      catch (Exception sqlExcept)
      {
      }
    }

    //This is necesary to unlock DB at the end
    closeDBbyServer();
  }
}