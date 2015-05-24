module maud.ui.procInfo;
import dlangui;
import maud.vm.vmi;
import maud.vm.constants;
import dlangui.widgets.metadata;
import maud.vm.util;
class ProcInfo : HorizontalLayout
{
	VMInterface vm;
	Button run_btn;
	Button stop_btn;
	Button step_btn;
	Button res_btn;
	WidgetHexAdapter onUpdate;
	this(VMInterface machine)
	{
		super();
		auto afhl = new TableLayout().colCount(4);
		addChild(afhl);
		afhl.addChild(new TextWidget("A_r","A"d)); 
		afhl.addChild(new RegisterLine(machine,RE.A));
		afhl.addChild(new RegisterLine(machine,RE.F));
		afhl.addChild(new TextWidget("F_r","F"d));
		afhl.addChild(new TextWidget("B_r","B"d)); 
		afhl.addChild(new RegisterLine(machine,RE.B));
		afhl.addChild(new RegisterLine(machine,RE.C));
		afhl.addChild(new TextWidget("C_r","C"d)); 
		afhl.addChild(new TextWidget("D_r","D"d)); 
		afhl.addChild(new RegisterLine(machine,RE.D));
		afhl.addChild(new RegisterLine(machine,RE.E));
		afhl.addChild(new TextWidget("E_r","E"d)); 
		afhl.addChild(new TextWidget("H_r","H"d)); 
		afhl.addChild(new RegisterLine(machine,RE.H));
		afhl.addChild(new RegisterLine(machine,RE.L));
		afhl.addChild(new TextWidget("L_r","L"d)); 

		auto ixpc = new TableLayout().colCount(2);
		addChild(ixpc);
		ixpc.addChild(new TextWidget("IX_r","IX"d)); 
		ixpc.addChild(new RegisterLine(machine,RE2.IX));
		ixpc.addChild(new TextWidget("IY_r","IY"d)); 
		ixpc.addChild(new RegisterLine(machine,RE2.IY));
		ixpc.addChild(new TextWidget("SP_r","SP"d)); 
		ixpc.addChild(new RegisterLine(machine,RE2.SP));
		ixpc.addChild(new TextWidget("PC_r","PC"d)); 
		ixpc.addChild(new RegisterLine(machine,RE2.PC));

		auto prime = new TableLayout().colCount(4);
		addChild(prime);
		prime.addChild(new TextWidget("A'_r","A'"d)); 
		prime.addChild(new RegisterLine(machine,RE.AP));
		prime.addChild(new RegisterLine(machine,RE.FP));
		prime.addChild(new TextWidget("F'_r","F'"d));
		prime.addChild(new TextWidget("B'_r","B'"d)); 
		prime.addChild(new RegisterLine(machine,RE.BP));
		prime.addChild(new RegisterLine(machine,RE.CP));
		prime.addChild(new TextWidget("C'_r","C'"d));
		prime.addChild(new TextWidget("D'_r","D'"d)); 
		prime.addChild(new RegisterLine(machine,RE.DP));
		prime.addChild(new RegisterLine(machine,RE.EP));
		prime.addChild(new TextWidget("E'_r","E'"d)); 
		prime.addChild(new TextWidget("H'_r","H'"d)); 
		prime.addChild(new RegisterLine(machine,RE.HP));
		prime.addChild(new RegisterLine(machine,RE.LP));
		prime.addChild(new TextWidget("L'_r","L'"d));
		
		auto flag = new TableLayout().colCount(2);
		flag.addChild(new TextWidget("C_f","C"d));
		flag.addChild(new FlagLine(machine, FLAG_MASK.C));
		flag.addChild(new TextWidget("N_f","N"d));
		flag.addChild(new FlagLine(machine, FLAG_MASK.N));
		flag.addChild(new TextWidget("PV_f","PV"d));
		flag.addChild(new FlagLine(machine, FLAG_MASK.PV));
		flag.addChild(new TextWidget("H_f","H"d));
		flag.addChild(new FlagLine(machine, FLAG_MASK.H));
		flag.addChild(new TextWidget("Z_f","Z"d));
		flag.addChild(new FlagLine(machine, FLAG_MASK.Z));
		flag.addChild(new TextWidget("S_f","S"d));
		flag.addChild(new FlagLine(machine, FLAG_MASK.S));
		addChild(flag);
		
		auto btns = new VerticalLayout();
		run_btn = new Button("RUN_b","Inicio"d);
		stop_btn = new Button("STOP_b", "Fin"d);
		step_btn = new Button("STEP_b", "Paso"d);
		res_btn = new Button("RES_b", "Reset"d);
		btns.addChild(run_btn);
		btns.addChild(stop_btn);
		btns.addChild(step_btn);
		btns.addChild(res_btn);
		addChild(btns);
		auto pts = new VerticalLayout();
		auto stack = new WidgetHexAdapter(machine);
		auto list = new ListWidget("STACK");
		auto scroll = new ScrollWidget();
		list.ownAdapter = stack;
		pts.addChild(new TextWidget("STACK_TITLE","Stack:   "d));
		scroll.contentWidget = list;
		scroll.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT).maxHeight(140).minHeight(140)
			.minWidth(30).maxWidth(30).state(ScrollBarMode.Auto);
		pts.addChild(scroll);
		addChild(pts);
		onUpdate = stack;
	}
}

private class RegisterLine : EditLine{
	this(VMInterface x, size_t reg){
		vm = x;
		this.reg = reg;
		readOnly = true;
	}
	override void onDraw(DrawBuf buf) {
		if (visibility != Visibility.Visible)
			return;
		super.onDraw(buf);
		Rect rc = _pos;
		applyMargins(rc);
		applyPadding(rc);
		auto saver = ClipRectSaver(buf, rc, alpha);
		FontRef font = font();
		dstring txt = reg < 80? HEX_MAP[vm.getRegister(reg)] : HEX_MAP[vm.getRegister(reg)>>8] ~
			HEX_MAP[vm.getRegister(reg)&0xFF];
		Point sz = font.textSize(txt);
		//applyAlign(rc, sz);
		Rect lineRect = _clientRect;
		lineRect.left = _clientRect.left - _scrollPos.x;
		lineRect.right = lineRect.left + calcLineWidth(txt);
		Rect visibleRect = lineRect;
		visibleRect.left = _clientRect.left;
		visibleRect.right = _clientRect.right;
		drawLineBackground(buf, lineRect, visibleRect);
		font.drawText(buf, rc.left - _scrollPos.x, rc.top, txt, textColor, tabSize);
		
		drawCaret(buf);
	}
	VMInterface vm;
	size_t reg;
}

private class FlagLine : EditLine{
	this(VMInterface x, FLAG_MASK flag){
		vm = x;
		this.reg = flag;
		readOnly = true;
	}
	override void onDraw(DrawBuf buf) {
		if (visibility != Visibility.Visible)
			return;
		super.onDraw(buf);
		Rect rc = _pos;
		applyMargins(rc);
		applyPadding(rc);
		auto saver = ClipRectSaver(buf, rc, alpha);
		FontRef font = font();
		dstring txt = (vm.getRegister(RE.F) & reg) > 0 ? "1" : "0";
		Point sz = font.textSize(txt);
		//applyAlign(rc, sz);
		Rect lineRect = _clientRect;
		lineRect.left = _clientRect.left - _scrollPos.x;
		lineRect.right = lineRect.left + calcLineWidth(txt);
		Rect visibleRect = lineRect;
		visibleRect.left = _clientRect.left;
		visibleRect.right = _clientRect.right;
		drawLineBackground(buf, lineRect, visibleRect);
		font.drawText(buf, rc.left - _scrollPos.x, rc.top, txt, textColor, tabSize);
		
		drawCaret(buf);
	}
	VMInterface vm;
	FLAG_MASK reg;
}

private class WidgetHexAdapter : ListAdapterBase {
	private WidgetList _widgets;
	VMInterface vmi;
	ulong last_size = 0;
	/// list of widgets to display
	@property ref const(WidgetList) widgets() {

		return _widgets;
	}
	/// returns number of widgets in list
	@property override int itemCount() const {
		return _widgets.count;
	}

	this(VMInterface v){
		vmi = v;
		update();
	}
	/// return list item widget by item index
	override Widget itemWidget(int index) {
		return _widgets.get(index);
	}
	/// return list item's state flags
	override uint itemState(int index) const {
		return _widgets.get(index).state;
	}
	/// set one or more list item's state flags, returns updated state
	override uint setItemState(int index, uint flags) {
		return _widgets.get(index).setState(flags).state;
	}
	/// reset one or more list item's state flags, returns updated state
	override uint resetItemState(int index, uint flags) {
		return _widgets.get(index).resetState(flags).state;
	}
	void update(){
		if(_widgets.count != vmi.getStackSize()){
			_widgets.clear;
			for(ushort i = 0; i< vmi.getStackSize();i++){
				ushort idx = cast(ushort) (vmi.getRegister(RE2.SP) + (i<<1));
				ubyte value2 = *vmi.memory.getAddress(idx+1);
				ubyte value = *vmi.memory.getAddress(idx);
				_widgets.insert(new TextWidget("ELEM",HEX_MAP[value2]~HEX_MAP[value]),i); 
			}
			updateViews();
		}

	}

	/// remove all items
	override void clear() {
		_widgets.clear();
		updateViews();
	}
	~this() {
		//Log.d("Destroying WidgetListAdapter");
	}
}