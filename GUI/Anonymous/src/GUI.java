import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.IOException;
import java.util.ArrayList;

import javax.swing.*;

import com.ericsson.otp.erlang.OtpErlangDecodeException;
import components.TorrentFilter;

public class GUI {
	
	static JLayeredPane pane;
	protected JLabel menuborder;
	protected ImageIcon border;
	public static MenuState currentMenu;
	protected Container conn;
	protected static ImageIcon fileContentImg;
    protected ImageIcon infoBarImg;
    protected ImageIcon buttonImg;
    protected static ImageIcon trashImg;
    protected static ImageIcon startImg;
    protected static ImageIcon stopImg;
    protected static ImageIcon pauseImg;
    protected ImageIcon addImg;
    protected ImageIcon downloadDirImg;
    protected JLabel buttonBoarder;
    protected JButton addButton;
    protected static JButton startButton;
    protected static JButton pauseButton;
    protected static JButton trashButton;
    protected static JButton stopButton;
    protected JButton downloadDirButton;
    protected static JButton fileContentButton;
    protected JMenuBar menuBar;
    protected JMenu fileMenu;
    protected JMenuItem menuItem;
    protected ActionListener openTorrentListener;
    protected ActionListener openUrlTorrentListener;
    protected ActionListener optionMenuItemListener;
    protected ActionListener aboutMenuItemListener;
    protected JMenu settingMenu;
    protected JMenu helpMenu;
    protected JMenuItem openUrlMenuItem;
    protected JMenuItem openMenuItem;
    protected JMenuItem optionMenuItem;
    protected JMenuItem aboutMenuItem;
    protected static JTextArea fileNameField;
    protected static JTextArea fileSizeField;
    protected static JTextArea trackerField;
    protected static JTextArea statusField;
    protected static JTextArea timeLeftField;
    protected static JTextArea downloadSpeedField;
    protected static JTextArea uploadSpeedField;
    protected static JTextArea seedersField;
    protected static JTextArea leechersField;
    protected static JTextArea downloadedField;
    protected static JTextArea uploadedField;
    protected static JTextArea defaultDirField;
    protected static JLabel openToStart;
    final JFileChooser fc = new JFileChooser();
    final JFileChooser fc2 = new JFileChooser();
    protected static JProgressBar progressBar;
    protected static TalkToErlang tte;
    static JFrame frame;
    protected static int fileSize;
    protected static JInternalFrame internalFrame;
    protected static Container internalContainer;
    protected static JTextArea internalTextArea;
    protected static ArrayList<String> files;
	
    public enum MenuState {
        MAIN, START, START2, START3
    }
    
    public GUI(TalkToErlang obj) {
    	frame = new JFrame("Anonymous");
        frame.setSize(1025, 573);
        frame.setPreferredSize(new Dimension(1025,573));
        frame.setIconImage(new ImageIcon("img/titleimg.png").getImage());
        fc2.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        tte = obj;
        setUpGui();
        
    }
    
    public static void displayMenu(MenuState current, final MenuState previous) {
        	undisplayMenu(); // we test this position first, before the change of currentMenu, to see how that works out
        	currentMenu = current;

        switch (currentMenu) {
        case MAIN: // do all the stuff needed to display the objects unique for main menu (intialize, set all bounds, add to layered pane etc etc)
        	openToStart = new JLabel("Add a torrent to start downloading");
        	openToStart.setFont(new Font("Aharoni", Font.BOLD, 30));
        	openToStart.setVisible(true);
        	openToStart.setBorder(null);
        	openToStart.setBounds(250,300,550,50);
            pane.add(openToStart,1);
            break;
        case START:
        	setTorrentState();
            break;

        case START2:


            break;
            
        case START3:
        	break;
        }
    }
    
    /**
     * Undisplays the components to be undisplayed. Sets them to not visible, then
     * to null. At last it calls the garbage collector, making sure that anything not visble
     * is not allocated in the memory.
     */
    public static void undisplayMenu() {

        switch (currentMenu) {
        case MAIN: // set all visual objects unique for main menu to null (this will work since this method will be called before the currentMenu is changed)
            if(openToStart != null) {
        	openToStart.setVisible(false);
            openToStart = null; 
            }
        	java.lang.Runtime.getRuntime().gc(); //this comes last just before break
            break;
        case START:
        	fileNameField.setVisible(false);
            fileNameField = null;
            fileSizeField.setVisible(false);
            fileSizeField = null;
            trackerField.setVisible(false);
            trackerField = null;
            statusField.setVisible(false);
            statusField = null;
            timeLeftField.setVisible(false);
            timeLeftField = null;
            trashButton.setVisible(false);
            trashButton = null;
            downloadSpeedField.setVisible(false);
            downloadSpeedField = null;
            uploadSpeedField.setVisible(false);
            uploadSpeedField = null;
            seedersField.setVisible(false);
            seedersField = null;
            leechersField.setVisible(false);
            leechersField = null;
            downloadedField.setVisible(false);
            downloadedField = null;
            uploadedField.setVisible(false);
            uploadedField = null;
            progressBar.setVisible(false);
            progressBar = null;
            startButton.setVisible(false);
            startButton = null;
            pauseButton.setVisible(false);
            pauseButton = null;
            stopButton.setVisible(false);
            stopButton = null;
            fileContentButton.setVisible(false);
            fileContentButton = null;
            java.lang.Runtime.getRuntime().gc();
            break;
//
//        case START2:
//            java.lang.Runtime.getRuntime().gc(); //this comes last just before break
//            break;
//        case START3:
//          java.lang.Runtime.getRuntime().gc(); //this comes last just before break
//          break;
        }

    }
    
    /**
     * Sets up the GUI at startup.
     */
    public void setUpGui() {
        currentMenu = MenuState.MAIN;
        frame.setLayout(new BorderLayout());
        frame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        frame.setResizable(false);
        files = new ArrayList<String>();

        frame.addWindowListener(new WindowAdapter()
        {
              public void windowClosing(WindowEvent e)
              {
            	  try {
					tte.sendMessage("exit");
					System.exit(0);
				} catch (Exception e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
              }
        });

        conn = frame.getContentPane();

        //layeredpane
        pane = new JLayeredPane();
        pane.setBounds(0, 25, 1024, 600);

        // main jlabel
        border = new ImageIcon("resources/mainbar.png");
        menuborder = new JLabel(border);
        menuborder.setVisible(true);
        menuborder.setBounds(0, 100, border.getIconWidth(), border.getIconHeight());
        border = null;
        pane.add(menuborder, -1);

        //jlabel for Buttons
        buttonImg = new ImageIcon("resources/buttonbar.png");
        buttonBoarder = new JLabel(buttonImg);
        buttonBoarder.setVisible(true);
        buttonBoarder.setBounds(0,0,buttonImg.getIconWidth(),buttonImg.getIconHeight());
        buttonImg = null;
        pane.add(buttonBoarder, -1);
        
        addImg = new ImageIcon("resources/add.png");
        addButton = new JButton(addImg);
        addButton.setToolTipText("Open a new torrent file");
        addButton.setVisible(true);
        addButton.setBorder(null);
        addButton.setContentAreaFilled(false);
        addButton.setBounds(25,20,addImg.getIconWidth(),addImg.getIconHeight());
        addImg = null;
        pane.add(addButton,1);
        
        addButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	fc.addChoosableFileFilter(new TorrentFilter());
            	int returnval = fc.showOpenDialog(addButton);
            	if (returnval == JFileChooser.CANCEL_OPTION) {
            		System.out.println("canceled by user"); 
            	} else {
                	String path;
//                	undisplayMenu();
                	displayMenu(MenuState.START, MenuState.MAIN);
                	path = fc.getSelectedFile().getAbsolutePath();
                	fileNameField.setText("File name: " +fc.getSelectedFile().getName());
                	System.out.println(path);
                	try {
                	tte.sendMessage2("open", path);
                	statusField.setText("Status: " +"Active");
            		} catch (Exception e1) {
            			// TODO Auto-generated catch block
            			e1.printStackTrace();
            		}
            	}
            }
        });

        downloadDirImg = new ImageIcon("resources/downloaddir.png");
        downloadDirButton = new JButton(downloadDirImg);
        downloadDirButton.setVisible(true);
        downloadDirButton.setBorder(null);
        downloadDirButton.setToolTipText("Choose a download directory");
        downloadDirButton.setContentAreaFilled(false);
        downloadDirButton.setBounds(920,20,downloadDirImg.getIconWidth(),downloadDirImg.getIconHeight());
        downloadDirImg = null;
        pane.add(downloadDirButton,1);
        
        
        downloadDirButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	int returnval = fc2.showOpenDialog(downloadDirButton);
            	if (returnval == JFileChooser.CANCEL_OPTION) {
            		System.out.println("canceled by user"); 
            	} else {
                	String path;
                	path = fc2.getSelectedFile().getAbsolutePath();
                	System.out.println(path);
                	try {
                	tte.sendMessage2("dir", path);
                	defaultDirField.setText(path);
            		} catch (Exception e1) {
            			// TODO Auto-generated catch block
            			e1.printStackTrace();
            		}
            	}
            }
        });
        
        defaultDirField = new JTextArea();
        defaultDirField.setFont(new Font("Aharoni", 0, 10));
        defaultDirField.setVisible(true);
        defaultDirField.setBorder(null);
        defaultDirField.setOpaque(false);
        defaultDirField.setEditable(false);
        defaultDirField.setBounds(700,80,300,50);
        pane.add(defaultDirField, 0);
        
        //Menubar
        menuBar = new JMenuBar();
        //MenuItems
        helpMenu = new JMenu("Help");
        helpMenu.setMnemonic(KeyEvent.VK_F);
        menuBar.add(helpMenu);

        //Help Menu Items
        aboutMenuItem = new JMenuItem("About", KeyEvent.VK_N);
        helpMenu.add(aboutMenuItem);
        
        aboutMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	//about case or new frame?
            }
        });
        
        displayMenu(MenuState.MAIN, MenuState.MAIN);
        conn.add(pane);
        frame.setJMenuBar(menuBar);
        frame.pack();
        frame.setVisible(true);
    }
    	public static void setTorrentState() {
    		
    		 startImg = new ImageIcon("resources/play.png");
             startButton = new JButton(startImg);
             startButton.setToolTipText("Starts a paused or stopped torrent");
             startButton.setVisible(false);
             startButton.setBorder(null);
             startButton.setContentAreaFilled(false);
             startButton.setBounds(150,20,startImg.getIconWidth(),startImg.getIconHeight());
             startImg = null;
             pane.add(startButton,1);
             
             startButton.addActionListener(new ActionListener() {
                 public void actionPerformed(ActionEvent e) {
     				try {
     					tte.sendMessage("start");
     					startButton.setVisible(false);
     					pauseButton.setVisible(true);
     					stopButton.setVisible(true);
     					statusField.setText("Status: " +"Active");
     				} catch (Exception e1) {
     					// TODO Auto-generated catch block
     					e1.printStackTrace();
     				}
                 }
             });
             
             pauseImg = new ImageIcon("resources/pause.png");
             pauseButton = new JButton(pauseImg);
             pauseButton.setVisible(true);
             pauseButton.setBorder(null);
             pauseButton.setToolTipText("Pauses torrent");
             pauseButton.setContentAreaFilled(false);
             pauseButton.setBounds(275,20,pauseImg.getIconWidth(),pauseImg.getIconHeight());
             pauseImg = null;
             pane.add(pauseButton,1);
             
             pauseButton.addActionListener(new ActionListener() {
                 public void actionPerformed(ActionEvent e) {
                 	System.out.println("1");
     							try {
     								pauseButton.setVisible(false);
     								stopButton.setVisible(false);
     								startButton.setVisible(true);
     								tte.sendMessage("pause");
     								statusField.setText("Status: " +"Paused");
     							} catch (Exception e1) {
     								// TODO Auto-generated catch block
     								e1.printStackTrace();
     							}
                 }
             });
             
             stopImg = new ImageIcon("resources/stop.png");
             stopButton = new JButton(stopImg);
             stopButton.setVisible(true);
             stopButton.setToolTipText("Stops a downloading torrent");
             stopButton.setBorder(null);
             stopButton.setContentAreaFilled(false);
             stopButton.setBounds(400,20,stopImg.getIconWidth(),stopImg.getIconHeight());
             pane.add(stopButton,1);
             stopImg = null;
             
             stopButton.addActionListener(new ActionListener() {
                 public void actionPerformed(ActionEvent e) {
     							try {
     								stopButton.setVisible(false);
     								pauseButton.setVisible(false);
     								startButton.setVisible(true);
     								tte.sendMessage("stop");
     								statusField.setText("Status: " +"Stopped");
     							} catch (Exception e1) {
     								// TODO Auto-generated catch block
     								e1.printStackTrace();
     							}
                 
                 }
             });
             
             fileContentImg = new ImageIcon("resources/files.png");
             fileContentButton = new JButton(fileContentImg);
             fileContentButton.setVisible(true);
             fileContentButton.setToolTipText("Display downloading content");
             fileContentButton.setBorder(null);
             fileContentButton.setContentAreaFilled(false);
             fileContentButton.setBounds(20,320,fileContentImg.getIconWidth(),fileContentImg.getIconHeight());
             pane.add(fileContentButton,1);
             fileContentImg = null;
             
             fileContentButton.addActionListener(new ActionListener() {
                 public void actionPerformed(ActionEvent e) {
                	 internalFrame = new JInternalFrame("Files downloading");
                	 internalFrame.setSize(300, 300);
                	 internalFrame.setVisible(true);
                	 internalFrame.setLocation(400, 200);
                	 internalFrame.setClosable(true);
                	 pane.add(internalFrame, 0);
                	 internalTextArea = new JTextArea();
                	 internalTextArea.setBounds(0, 0, 400, 200);
                	 internalTextArea.setVisible(true);
                	 internalTextArea.setFont(new Font("Aharoni", 0, 15));
                	 internalTextArea.setBackground(Color.orange);
                	 internalContainer = internalFrame.getContentPane();
                	 String text = "";
                	 for (int i = 0; i < files.size(); i++) {
                		 text += files.get(i) + "\n";
                	 }
                	 internalTextArea.setText(text);
                	 internalContainer.add(internalTextArea);
                 }
             });
             
             trashImg = new ImageIcon("resources/trash.png");
             trashButton = new JButton();
             trashButton.setIcon(trashImg);
             trashButton.setVisible(true);
             trashButton.setToolTipText("Remove torrent");
             trashButton.setContentAreaFilled(false);
             trashButton.setBorder(null);
             trashButton.setBounds(525,20,trashImg.getIconWidth(),trashImg.getIconHeight());
             trashImg = null;
             pane.add(trashButton,1);
             
             trashButton.addActionListener(new ActionListener() {
                 public void actionPerformed(ActionEvent e) {
                    	int returnval = JOptionPane.showConfirmDialog(
                    		    frame,
                    		    "Would you really want to delete this torrent? all data will be lost",
                    		    "Delete torrent?",
                    		    JOptionPane.YES_NO_OPTION);
                 	if (returnval == JOptionPane.NO_OPTION) {
                 		System.out.println("canceled by user"); 
                 	} else {
     				try {
     					displayMenu(MenuState.MAIN, MenuState.START);
     					tte.sendMessage("delete");
     				} catch (Exception e1) {
     					// TODO Auto-generated catch block
     					e1.printStackTrace();
     				}
                 	}
                 }
             });

             //TextFields for information about torrent(filename, size, tracker)       
             fileNameField = new JTextArea("File name:");
             fileNameField.setFont(new Font("Aharoni", 0, 20));
             fileNameField.setVisible(true);
             fileNameField.setBorder(null);
             fileNameField.setOpaque(false);
             fileNameField.setEditable(false);
             fileNameField.setBounds(20, 120, 500, 50);
             pane.add(fileNameField, 0);
             
             fileSizeField = new JTextArea("File size:");
             fileSizeField.setFont(new Font("Aharoni", 0, 20));
             fileSizeField.setVisible(true);
             fileSizeField.setBorder(null);
             fileSizeField.setOpaque(false);
             fileSizeField.setEditable(false);
             fileSizeField.setBounds(20, 170, 400, 50);
             pane.add(fileSizeField, 0);
             
             trackerField = new JTextArea("Tracker:");
             trackerField.setFont(new Font("Aharoni", 0, 20));
             trackerField.setVisible(true);
             trackerField.setBorder(null);
             trackerField.setOpaque(false);
             trackerField.setEditable(false);
             trackerField.setBounds(20, 220, 400, 50);
             pane.add(trackerField, 0);
             
             statusField = new JTextArea("Status:");
             statusField.setFont(new Font("Aharoni", 0, 20));
             statusField.setVisible(true);
             statusField.setBorder(null);
             statusField.setOpaque(false);
             statusField.setEditable(false);
             statusField.setBounds(20, 270, 400, 50);
             pane.add(statusField, 0);
             
             timeLeftField = new JTextArea("Time left:");
             timeLeftField.setFont(new Font("Aharoni", 0, 20));
             timeLeftField.setVisible(true);
             timeLeftField.setBorder(null);
             timeLeftField.setOpaque(false);
             timeLeftField.setEditable(false);
             timeLeftField.setBounds(750, 120, 200, 50);
             pane.add(timeLeftField, 0);
             
             //seeders,leechers,download & upload speeds
             downloadSpeedField = new JTextArea("Download speed:");
             downloadSpeedField.setFont(new Font("Aharoni", 0, 20));
             downloadSpeedField.setVisible(true);
             downloadSpeedField.setBorder(null);
             downloadSpeedField.setOpaque(false);
             downloadSpeedField.setEditable(false);
             downloadSpeedField.setBounds(20, 420, 200, 50);
             pane.add(downloadSpeedField, 0);
             
             uploadSpeedField = new JTextArea("Upload speed:");
             uploadSpeedField.setFont(new Font("Aharoni", 0, 20));
             uploadSpeedField.setVisible(true);
             uploadSpeedField.setBorder(null);
             uploadSpeedField.setOpaque(false);
             uploadSpeedField.setEditable(false);
             uploadSpeedField.setBounds(260, 420, 200, 50);
             pane.add(uploadSpeedField, 0);
             
             seedersField = new JTextArea("Seeders:");
             seedersField.setFont(new Font("Aharoni", 0, 20));
             seedersField.setVisible(true);
             seedersField.setBorder(null);
             seedersField.setOpaque(false);
             seedersField.setEditable(false);
             seedersField.setBounds(500, 420, 200, 50);
             pane.add(seedersField, 0);
             
             leechersField = new JTextArea("Leechers:");
             leechersField.setFont(new Font("Aharoni", 0, 20));
             leechersField.setVisible(true);
             leechersField.setBorder(null);
             leechersField.setOpaque(false);
             leechersField.setEditable(false);
             leechersField.setBounds(740, 420, 200, 50);
             pane.add(leechersField, 0);
             
             downloadedField = new JTextArea("Downloaded:");
             downloadedField.setFont(new Font("Aharoni", 0, 20));
             downloadedField.setVisible(true);
             downloadedField.setBorder(null);
             downloadedField.setOpaque(false);
             downloadedField.setEditable(false);
             downloadedField.setBounds(750, 170, 200, 50);
             pane.add(downloadedField, 0);
             
             uploadedField = new JTextArea("Uploaded:");
             uploadedField.setFont(new Font("Aharoni", 0, 20));
             uploadedField.setVisible(true);
             uploadedField.setBorder(null);
             uploadedField.setOpaque(false);
             uploadedField.setEditable(false);
             uploadedField.setBounds(750, 220, 200, 50);
             pane.add(uploadedField, 0);
             
             //Progress Bar
             progressBar = new JProgressBar(0, 100);
             progressBar.setValue(0);
             progressBar.setStringPainted(true);
             progressBar.setVisible(true);
             progressBar.setForeground(Color.ORANGE);
             progressBar.setBackground(Color.black);
             progressBar.setFont(new Font("Aharoni", 0, 25));
             progressBar.setBounds(20, 450, 980, 50);
             pane.add(progressBar, 0);
    	}
    	public static void setField(String torrentId, int tag,String value) {
    		switch (tag) {
    		case 1: if (fileSizeField != null) {
    			fileSizeField.setText("File size: " + value + " Mb");
    			fileSize = Integer.parseInt(value);
    		}
    		break;
    		case 2: if (trackerField != null) 
    			trackerField.setText("Tracker: " + value);
    		break;
    		case 3: if (downloadSpeedField != null)
    			downloadSpeedField.setText("Download speed: " + value +" Kb/s");
    		break;
    		case 4: if (uploadSpeedField != null)
    			uploadSpeedField.setText("Upload speed: " + value +" Kb/s");
    		break;
    		case 5: if (seedersField != null)
    			seedersField.setText("Seeders: " + value);
    		break;
    		case 6: if (leechersField != null)
    			leechersField.setText("Leechers: " + value);
    		break;
    		case 7: if (downloadedField != null) {
    			downloadedField.setText("Downloaded: " +value + "Mb");
    			progressBar.setValue((int)(Integer.parseInt(value)/(double)fileSize*100));
    		}
    		break;
    		case 8: if (uploadedField != null)
    			uploadedField.setText("Downloaded: " +value + "Mb");
    		break;
    		case 9: displayMenu(MenuState.MAIN, MenuState.START);
    				JOptionPane.showMessageDialog(frame,
    				value);
    		break;
    		case 10: files.add(value);
    		break;
    		}
    	}

    
    

}
