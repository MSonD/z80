module maud.ui.app;

import dlangui;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.dialog;
import maud.ui.binaryGrid;
import maud.ui.stringHistory;
import maud.ui.procInfo;
import maud.glue.maudInterface;

class MainApp 
{
	Window window;
	Window log_window;
	EditLine cmd;
	ApplicationContext c;
	StringHistory history;
	RunWidget timer;
	LogWidget log;

	this(ApplicationContext c)
	{
		this.c = c;
		timer = new RunWidget();
		history = new StringHistory();
		window = Platform.instance.createWindow("Maud Z80 Emulator v0.1", null);
		log_window = Platform.instance.createWindow("Log",window);
		auto mem = c.VM.memory;
		
		BinaryGridWidget grid = new BinaryGridWidget("GRID1",c.VM);
		grid.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
		grid.showColHeaders = true;
		grid.showRowHeaders = true;
		grid.resize(16,0);
		
		//grid.rowSelect = true; // testing full row selection
		grid.autoFit();
		
		// create some widget to show in window
		//window.onResize(grid.fullContentSize.x, grid.fullContentSize.y);

		VerticalLayout lay = new VerticalLayout("WinLayout");
		lay.addChild(grid);
		auto info = new ProcInfo(c.VM);
		lay.addChild(info);
		info.run_btn.addOnClickListener( delegate bool (Widget x){
				timer.running = true;
				return true;
			});
		info.stop_btn.addOnClickListener( delegate bool (Widget x){
				timer.running = false;
				return true;
			});
		info.res_btn.addOnClickListener( delegate bool(Widget x){
				c.VM.restart();
				info.onUpdate.update();
				timer.running = false;
				return true;
			});
		info.step_btn.addOnClickListener( delegate bool(Widget x){
				c.VM.executeStep();
				info.onUpdate.update();
				return true;
			});
		cmd = new EditLine("CommandBox"," ");

		cmd.keyEvent = delegate bool  (Widget x, KeyEvent evt) {
			if(evt.keyCode == KeyCode.RETURN && evt.action == KeyAction.KeyUp){
				try{
					c.command(x.text);
					history.push(x.text);
					history.rewind();
					cmd.text = "";
				}catch(Exception e){
					cmd.text = "";
					log.appendText(e.msg.toUTF32);
					log.appendText("\n"d);
				}
				return true;
			}else if(evt.keyCode == KeyCode.UP && evt.action == KeyAction.KeyUp){
				cmd.text = history.pop();
				return true;
			}else if(evt.keyCode == KeyCode.DOWN && evt.action == KeyAction.KeyUp){
				cmd.text = history.dePop();
				return true;
			}else return false;
		};
		timer.onRun = delegate void () {c.VM.executeStep;info.onUpdate.update;};
		lay.addChild(cmd);
		lay.addChild(timer);
		log = new LogWidget();
		log_window.mainWidget = log;
		window.mainWidget = lay;

		c.getLua()["open"] = &openFile;
		// show window, does not work on Windows
		version(Windows){}else{
			log_window.show();
		}
		window.show();
	}

	void openFile(){
		FileDialog dlg = new FileDialog(UIString("Abrir"d),window);
		dlg.onDialogResult = delegate(Dialog dlg, const Action result) {
			if (result.id == ACTION_OPEN.id) {
				string filename = result.stringParam;
				try{
				c.load(filename);
				}catch(Exception e){
					log.appendText("Error opening file\n"d);
				}
			}
		};
		dlg.show();
	}

	bool onEditorAction(const Action action){
		return true;
	}


}

class RunWidget : Widget{
	bool running = false;
	void delegate() onRun;
	override void animate(long interval) {
		onRun();
	}
	override @property bool animating() {
		return running;
	}
}
