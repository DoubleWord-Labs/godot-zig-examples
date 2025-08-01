const Self = @This();

const Examples = [_]struct { name: [:0]const u8, T: type }{
    .{ .name = "Sprites", .T = SpritesNode },
    .{ .name = "GUI", .T = GuiNode },
    .{ .name = "Signals", .T = SignalNode },
};

base: Node,
panel: PanelContainer,
example_node: ?Node = null,

property1: Vector3,
property2: Vector3,

fps_counter: Label,

const property1_name: [:0]const u8 = "Property1";
const property2_name: [:0]const u8 = "Property2";

pub fn init(self: *Self) void {
    std.log.info("init {s}", .{@typeName(@TypeOf(self))});

    self.fps_counter = Label.init();
    self.fps_counter.setPosition(.{ .x = 50, .y = 50 }, false);
    self.base.addChild(self.fps_counter, false, 0);
}

pub fn deinit(self: *Self) void {
    std.log.info("deinit {s}", .{@typeName(@TypeOf(self))});
}

pub fn _process(self: *Self, delta: f64) void {
    _ = delta;

    const engine = Engine.getSingleton();

    const window = self.base.getTree().?.getRoot().?;
    const sz = window.getSize();

    const label_size = self.fps_counter.getSize();
    self.fps_counter.setPosition(.{ .x = @floatFromInt(25), .y = @as(f32, @floatFromInt(sz.y - 25)) - label_size.y }, false);

    var fps_buf: [64]u8 = undefined;
    const fps = std.fmt.bufPrint(&fps_buf, "FPS: {d}", .{engine.getFramesPerSecond()}) catch @panic("Failed to format FPS");
    self.fps_counter.setText(fps);
}

fn clear_scene(self: *Self) void {
    if (self.example_node) |n| {
        godot.destroy(n);
        //n.queue_free(); //ok
    }
}

pub fn on_timeout(_: *Self) void {
    std.debug.print("on_timeout\n", .{});
}

pub fn on_resized(_: *Self) void {
    std.debug.print("on_resized\n", .{});
}

pub fn on_item_focused(self: *Self, idx: i64) void {
    self.clear_scene();
    switch (idx) {
        inline 0...Examples.len - 1 => |i| {
            const n = godot.create(Examples[i].T) catch unreachable;
            self.example_node = godot.cast(Node, n.base);
            self.panel.addChild(self.example_node, false, Node.INTERNAL_MODE_DISABLED);
            self.panel.grabFocus();
        },
        else => {},
    }
}

pub fn _enter_tree(self: *Self) void {
    inline for (Examples) |E| {
        godot.registerClass(E.T);
    }

    //initialize fields
    self.example_node = null;
    self.property1 = Vector3.new(111, 111, 111);
    self.property2 = Vector3.new(222, 222, 222);

    if (Engine.getSingleton().isEditorHint()) return;

    const window_size = self.base.getTree().?.getRoot().?.getSize();
    var sp = HSplitContainer.init();
    sp.setHSizeFlags(Control.SIZE_EXPAND_FILL);
    sp.setVSizeFlags(Control.SIZE_EXPAND_FILL);
    sp.setSplitOffset(@intFromFloat(@as(f32, @floatFromInt(window_size.x)) * 0.2));
    sp.setAnchorsPreset(Control.PRESET_FULL_RECT, false);
    var itemList = ItemList.init();
    inline for (0..Examples.len) |i| {
        _ = itemList.addItem(Examples[i].name, null, true);
    }
    var timer = self.base.getTree().?.createTimer(1.0, true, false, false);
    defer _ = timer.?.unreference();

    godot.connect(timer.?, "timeout", self, "on_timeout");
    godot.connect(sp, "resized", self, "on_resized");

    godot.connect(itemList, "item_selected", self, "on_item_focused");
    self.panel = PanelContainer.init();
    self.panel.setHSizeFlags(Control.SIZE_FILL);
    self.panel.setVSizeFlags(Control.SIZE_FILL);
    self.panel.setFocusMode(Control.FOCUS_ALL);
    sp.addChild(itemList, false, Node.INTERNAL_MODE_DISABLED);
    sp.addChild(self.panel, false, Node.INTERNAL_MODE_DISABLED);
    self.base.addChild(sp, false, Node.INTERNAL_MODE_DISABLED);
}

pub fn _exit_tree(self: *Self) void {
    _ = self;
}

pub fn _notification(self: *Self, what: i32) void {
    if (what == Node.NOTIFICATION_WM_CLOSE_REQUEST) {
        if (!Engine.getSingleton().isEditorHint()) {
            self.base.getTree().?.quit(0);
        }
    }
}

pub fn _get_property_list(_: *Self) []const PropertyInfo {
    const C = struct {
        var properties: [32]PropertyInfo = undefined;
    };

    C.properties[0] = PropertyInfo.init(godot.c.GDEXTENSION_VARIANT_TYPE_VECTOR3, StringName.initFromLatin1Chars(property1_name));
    C.properties[1] = PropertyInfo.init(godot.c.GDEXTENSION_VARIANT_TYPE_VECTOR3, StringName.initFromLatin1Chars(property2_name));

    return C.properties[0..2];
}

pub fn _property_can_revert(_: *Self, name: StringName) bool {
    if (name.casecmpTo(property1_name) == 0) {
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        return true;
    }

    return false;
}

pub fn _property_get_revert(_: *Self, name: StringName, value: *Variant) bool {
    if (name.casecmpTo(property1_name) == 0) {
        value.* = Variant.initFrom(Vector3.new(42, 42, 42));
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        value.* = Variant.initFrom(Vector3.new(24, 24, 24));
        return true;
    }

    return false;
}

pub fn _set(self: *Self, name: StringName, value: Variant) bool {
    if (name.casecmpTo(property1_name) == 0) {
        self.property1 = value.as(Vector3);
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        self.property2 = value.as(Vector3);
        return true;
    }

    return false;
}

pub fn _get(self: *Self, name: StringName, value: *Variant) bool {
    if (name.casecmpTo(property1_name) == 0) {
        value.* = Variant.initFrom(self.property1);
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        value.* = Variant.initFrom(self.property2);
        return true;
    }

    return false;
}

pub fn _to_string(_: *Self) ?String {
    return String.initFromLatin1Chars("ExampleNode");
}

const std = @import("std");
const godot = @import("godot");
const Control = godot.core.Control;
const Engine = godot.core.Engine;
const HSplitContainer = godot.core.HSplitContainer;
const ItemList = godot.core.ItemList;
const Label = godot.core.Label;
const Node = godot.core.Node;
const PanelContainer = godot.core.PanelContainer;
const PropertyInfo = godot.PropertyInfo;
const String = godot.core.String;
const StringName = godot.core.StringName;
const Variant = godot.Variant;
const Vector3 = godot.Vector3;

const SpritesNode = @import("SpriteNode.zig");
const GuiNode = @import("GuiNode.zig");
const SignalNode = @import("SignalNode.zig");
