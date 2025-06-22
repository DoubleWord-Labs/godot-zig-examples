const std = @import("std");
const godot = @import("godot");
const Vec2 = godot.Vector2;
const Vec3 = godot.Vector3;
const SpritesNode = @import("SpriteNode.zig");
const GuiNode = @import("GuiNode.zig");
const SignalNode = @import("SignalNode.zig");
const Examples = [_]struct { name: [:0]const u8, T: type }{
    .{ .name = "Sprites", .T = SpritesNode },
    .{ .name = "GUI", .T = GuiNode },
    .{ .name = "Signals", .T = SignalNode },
};

const Self = @This();

base: godot.Node,
panel: godot.PanelContainer,
example_node: ?godot.Node = null,

property1: Vec3,
property2: Vec3,

fps_counter: godot.Label,

const property1_name: [:0]const u8 = "Property1";
const property2_name: [:0]const u8 = "Property2";

pub fn init(self: *Self) void {
    std.log.info("init {s}", .{@typeName(@TypeOf(self))});

    self.fps_counter = godot.initLabel();
    self.fps_counter.setPosition(.{ .x = 50, .y = 50 }, false);
    self.base.addChild(self.fps_counter, false, 0);
}

pub fn deinit(self: *Self) void {
    std.log.info("deinit {s}", .{@typeName(@TypeOf(self))});
}

pub fn _process(self: *Self, delta: f64) void {
    _ = delta;

    const engine = godot.Engine.getSingleton();

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
            self.example_node = godot.cast(godot.Node, n.base);
            self.panel.addChild(self.example_node, false, godot.Node.INTERNAL_MODE_DISABLED);
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
    self.property1 = Vec3.new(111, 111, 111);
    self.property2 = Vec3.new(222, 222, 222);

    if (godot.Engine.getSingleton().isEditorHint()) return;

    const window_size = self.base.getTree().?.getRoot().?.getSize();
    var sp = godot.initHSplitContainer();
    sp.setHSizeFlags(godot.Control.SIZE_EXPAND_FILL);
    sp.setVSizeFlags(godot.Control.SIZE_EXPAND_FILL);
    sp.setSplitOffset(@intFromFloat(@as(f32, @floatFromInt(window_size.x)) * 0.2));
    sp.setAnchorsPreset(godot.Control.PRESET_FULL_RECT, false);
    var itemList = godot.initItemList();
    inline for (0..Examples.len) |i| {
        _ = itemList.addItem(Examples[i].name, null, true);
    }
    var timer = self.base.getTree().?.createTimer(1.0, true, false, false);
    defer _ = timer.?.unreference();

    godot.connect(timer.?, "timeout", self, "on_timeout");
    godot.connect(sp, "resized", self, "on_resized");

    godot.connect(itemList, "item_selected", self, "on_item_focused");
    self.panel = godot.initPanelContainer();
    self.panel.setHSizeFlags(godot.Control.SIZE_FILL);
    self.panel.setVSizeFlags(godot.Control.SIZE_FILL);
    self.panel.setFocusMode(godot.Control.FOCUS_ALL);
    sp.addChild(itemList, false, godot.Node.INTERNAL_MODE_DISABLED);
    sp.addChild(self.panel, false, godot.Node.INTERNAL_MODE_DISABLED);
    self.base.addChild(sp, false, godot.Node.INTERNAL_MODE_DISABLED);
}

pub fn _exit_tree(self: *Self) void {
    _ = self;
}

pub fn _notification(self: *Self, what: i32) void {
    if (what == godot.Node.NOTIFICATION_WM_CLOSE_REQUEST) {
        if (!godot.Engine.getSingleton().isEditorHint()) {
            self.base.getTree().?.quit(0);
        }
    }
}

pub fn _get_property_list(_: *Self) []const godot.PropertyInfo {
    const C = struct {
        var properties: [32]godot.PropertyInfo = undefined;
    };

    C.properties[0] = godot.PropertyInfo.init(godot.GDEXTENSION_VARIANT_TYPE_VECTOR3, godot.StringName.initFromLatin1Chars(property1_name));
    C.properties[1] = godot.PropertyInfo.init(godot.GDEXTENSION_VARIANT_TYPE_VECTOR3, godot.StringName.initFromLatin1Chars(property2_name));

    return C.properties[0..2];
}

pub fn _property_can_revert(_: *Self, name: godot.StringName) bool {
    if (name.casecmpTo(property1_name) == 0) {
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        return true;
    }

    return false;
}

pub fn _property_get_revert(_: *Self, name: godot.StringName, value: *godot.Variant) bool {
    if (name.casecmpTo(property1_name) == 0) {
        value.* = godot.Variant.initFrom(Vec3.new(42, 42, 42));
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        value.* = godot.Variant.initFrom(Vec3.new(24, 24, 24));
        return true;
    }

    return false;
}

pub fn _set(self: *Self, name: godot.StringName, value: godot.Variant) bool {
    if (name.casecmpTo(property1_name) == 0) {
        self.property1 = value.as(Vec3);
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        self.property2 = value.as(Vec3);
        return true;
    }

    return false;
}

pub fn _get(self: *Self, name: godot.StringName, value: *godot.Variant) bool {
    if (name.casecmpTo(property1_name) == 0) {
        value.* = godot.Variant.initFrom(self.property1);
        return true;
    } else if (name.casecmpTo(property2_name) == 0) {
        value.* = godot.Variant.initFrom(self.property2);
        return true;
    }

    return false;
}

pub fn _to_string(_: *Self) ?godot.String {
    return godot.String.initFromLatin1Chars("ExampleNode");
}
