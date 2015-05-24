module maud.ui.binaryGrid;
import dlangui;
import maud.vm.vmi;
import maud.vm.util;

class BinaryGridWidget : StringGridWidgetBase{
	
	protected VMInterface _bdata;

	/// empty parameter list constructor - for usage by factory
	this() {
		this(null,null);
	}
	/// create with ID parameter
	this(string ID, VMInterface mem) {
		super(ID);
		_bdata = mem;
		styleId = STYLE_EDIT_BOX;
		onThemeChanged();
	}

	@property setMemory(VMInterface x){
		_bdata = x;
	}
	
	/// get cell text
	override dstring cellText(int col, int row) {
		if (col*rows + row < _bdata.getNetSize){
			return HEX_MAP[*_bdata.memory.getAddress(row*cols+col)];
		}

		return ""d;
	}
	
	/// set cell text
	override StringGridWidgetBase setCellText(int col, int row, dstring text) {/+
		if (col >= 0 && col < cols && row >= 0 && row < rows)
			_data[row][col] = text;
			+/
		return this;
	}
	
	/// set new size
	override void resize(int c, int r) {
		if ((c == cols && r == rows) || c > 0xFF)
			return;
		int oldcols = cols;
		int oldrows = rows;
		r = cast(uint)(_bdata.getNetSize)/c;
		super.resize(c, r);/+
		_data.length = r;
		for (int y = 0; y < r; y++)
			_data[y].length = c;
		_colTitles.length = c;
		_rowTitles.length = r;
		+/
	}
	
	/// returns row header title
	override dstring rowTitle(int row) {
		return binToStrd(cast(ushort)(row*cols));
	}
	/// set row header title
	override StringGridWidgetBase setRowTitle(int row, dstring title) {
		/+_rowTitles[row] = title;+/
		return this;
	}
	
	/// returns row header title
	override dstring colTitle(int col) {
		return HEX_MAP[cast(ubyte)col];
	}
	
	/// set col header title
	override StringGridWidgetBase setColTitle(int col, dstring title) {
		/+_colTitles[col] = title;+/
		return this;
	}
	
	protected override Point measureCell(int x, int y) {
		if (_customCellAdapter && _customCellAdapter.isCustomCell(x, y)) {
			return _customCellAdapter.measureCell(x, y);
		}
		//Log.d("measureCell ", x, ", ", y);
		FontRef fnt = font;
		dstring txt;
		if (x >= 0 && y >= 0)
			txt = cellText(x, y);
		else if (y < 0 && x >= 0)
			txt = colTitle(x);
		else if (y >= 0 && x < 0)
			txt = rowTitle(y);
		Point sz = fnt.textSize(txt);
		if (sz.y < fnt.height)
			sz.y = fnt.height;
		return sz;
	}
	
	
	/// draw cell content
	protected override void drawCell(DrawBuf buf, Rect rc, int col, int row) {
		if (_customCellAdapter && _customCellAdapter.isCustomCell(col, row)) {
			return _customCellAdapter.drawCell(buf, rc, col, row);
		}
		rc.shrink(2, 1);
		FontRef fnt = font;
		dstring txt = cellText(col, row);
		Point sz = fnt.textSize(txt);
		Align ha = Align.Left;
		applyAlign(rc, sz, ha, Align.VCenter);
		fnt.drawText(buf, rc.left + 1, rc.top + 1, txt, textColor);
	}
	
	/// draw cell content
	protected override void drawHeaderCell(DrawBuf buf, Rect rc, int col, int row) {
		rc.shrink(2, 1);
		FontRef fnt = font;
		dstring txt;
		if (row < 0 && col >= 0)
			txt = colTitle(col);
		else if (row >= 0 && col < 0)
			txt = rowTitle(row);
		if (!txt.length)
			return;
		Point sz = fnt.textSize(txt);
		Align ha = Align.Left;
		if (col < 0)
			ha = Align.Right;
		if (row < 0)
			ha = Align.HCenter;
		applyAlign(rc, sz, ha, Align.VCenter);
		fnt.drawText(buf, rc.left + 1, rc.top + 1, txt, textColor);
	}
	
	/// draw cell background
	protected override void drawHeaderCellBackground(DrawBuf buf, Rect rc, int c, int r) {
		Rect vborder = rc;
		Rect hborder = rc;
		vborder.left = vborder.right - 1;
		hborder.top = hborder.bottom - 1;
		hborder.right--;
		bool selectedCol = (c == col) && !_rowSelect;
		bool selectedRow = r == row;
		bool selectedCell = selectedCol && selectedRow;
		if (_rowSelect && selectedRow)
			selectedCell = true;
		// draw header cell background
		uint cl = _cellHeaderBackgroundColor;
		if (c >= _headerCols || r >= _headerRows) {
			if (c < _headerCols && selectedRow)
				cl = _cellHeaderSelectedBackgroundColor;
			if (r < _headerRows && selectedCol)
				cl = _cellHeaderSelectedBackgroundColor;
		}
		buf.fillRect(rc, cl);
		buf.fillRect(vborder, _cellHeaderBorderColor);
		buf.fillRect(hborder, _cellHeaderBorderColor);
	}
	
	
	/// handle theme change: e.g. reload some themed resources
	override void onThemeChanged() {
		_selectionColor = style.customColor("grid_selection_color", 0x804040FF);
		_selectionColorRowSelect = style.customColor("grid_selection_color_row", 0xC0A0B0FF);
		_fixedCellBackgroundColor = style.customColor("grid_cell_background_fixed", 0xC0E0E0E0);
		_cellBorderColor = style.customColor("grid_cell_border_color", 0xC0C0C0C0);
		_cellHeaderBorderColor = style.customColor("grid_cell_border_color_header", 0xC0202020);
		_cellHeaderBackgroundColor = style.customColor("grid_cell_background_header", 0xC0909090);
		_cellHeaderSelectedBackgroundColor = style.customColor("grid_cell_background_header_selected", 0x80FFC040);
		super.onThemeChanged();
	}
	
	/// draw cell background
	protected override void drawCellBackground(DrawBuf buf, Rect rc, int c, int r) {
		Rect vborder = rc;
		Rect hborder = rc;
		vborder.left = vborder.right - 1;
		hborder.top = hborder.bottom - 1;
		hborder.right--;
		bool selectedCol = c == col;
		bool selectedRow = r == row;
		bool selectedCell = selectedCol && selectedRow;
		if (_rowSelect && selectedRow)
			selectedCell = true;
		// normal cell background
		if (c < _fixedCols || r < _fixedRows) {
			// fixed cell background
			buf.fillRect(rc, _fixedCellBackgroundColor);
		}
		buf.fillRect(vborder, _cellBorderColor);
		buf.fillRect(hborder, _cellBorderColor);
		if (selectedCell) {
			if (_rowSelect)
				buf.drawFrame(rc, _selectionColorRowSelect, Rect(0,1,0,1), _cellBorderColor);
			else
				buf.drawFrame(rc, _selectionColor, Rect(1,1,1,1), _cellBorderColor);
		}
	}
	
}

import dlangui.widgets.metadata;
mixin(registerWidgets!(BinaryGridWidget)());