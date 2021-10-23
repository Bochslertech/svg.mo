import Float "mo:base/Float";
import Int "mo:base/Int";
import Text "mo:base/Text";

module {
    private let emptyClose = "/>\n";

    public class SVG() {
        var svg : Text = "";

        // Begins the SVG document with the width w and height h.
        public func start(
            width  : Int,
            height : Int,
            as     : [Text],
        ) {
            svg #= "<?xml version=\"1.0\"?>\n<!-- Generated by svg.mo -->\n";
            svg #= "<svg width=\"" # Int.toText(width) # "\" height=\"" # Int.toText(height) # "\"";
            svg #= do {
                var a = "";
                for (v in as.vals()) {
                    a #= "\n     " # v;
                };
                a #= "\n     xmlns=\"http://www.w3.org/2000/svg\"";
                a #= "\n     xmlns:xlink=\"http://www.w3.org/1999/xlink\">\n";
                a;
            };
        };

        // Begins the SVG document, with the specified width, height, and viewbox.
        public func startView(
            width  : Int,
            height : Int,
            minX   : Int,
            minY   : Int,
            vw     : Int,
            vh     : Int,
        ) {
            start(
                width,
                height,
                ["viewBox=\"" # Int.toText(minX) # " " # Int.toText(minY) # " " #
                                Int.toText(vw)   # " " # Int.toText(vh)   # " " # "\""],
            );
        };

        // End the SVG document.
        public func end() : Text {
            svg # "</svg>";
        };

        // Defines the specified style (e.g. "text/css").
        public func style(scriptType : Text, data : [Text]) {
            svg #= embed("style", scriptType, data);
        };

        // Circle centered at (x, y) with radius r, with optional style.
        public func circle(x : Int, y : Int, r : Int, s : [Text]) {
            svg #= "<circle cx=\"" # Int.toText(x) # "\" cy=\"" # Int.toText(y) # "\" r=\"" # Int.toText(y) # "\" " # endStyle(s, emptyClose);
        };

        public func title(t : Text) {
            svg #= "<title>" # t # "</title>";
        };

        // Text places the specified text, t at x,y according to the style specified in s.
        public func text(x : Int, y : Int, t : Text, s : [Text]) {
            svg #= "<text " # Util.location(x, y) # " " # endStyle(s, ">");
            // TODO: escaping of t?
            svg #= t # "</text>\n";
        };

        // Defines a marker.
        public func marker(id : Text, x : Int, y : Int, w : Int, h : Int, s : [Text]) {
            svg #= "<marker id=\"" # id # "\" refX=\"" # Int.toText(x) # "\" refY=\"" # Int.toText(x) # "\"";
            svg #= " markerWidth=\"" # Int.toText(w) # "\" markerHeight=\"" # Int.toText(h) # "\" " # endStyle(s, ">\n");
        };

        // Ends a marker.
        public func markerEnd() {
            svg #= "</marker>";
        };

        // Draws connected lines between coordinates.
        public func polyline(xs : [Int], ys : [Int], s : [Text]) {
            pp(xs, ys, "<polyline points=\"");
            svg #= "\" " # endStyle(s, emptyClose);
        };

        private func pp(xs : [Int], ys : [Int], tag : Text) {
            svg #= tag;
            if (xs.size() != ys.size()) {
                svg #= " ";
                return;
            };
            for (i in xs.keys()) {
                svg #= Util.coordinate(xs[i], ys[i]);
                if (i != xs.size()) {
                    svg #= " ";
                };
            };
        };

        // Def begins a defintion block.
        public func def() {
            svg #= "<defs>" # "\n";
        };

        // Ends a defintion block.
        public func defEnd() {
            svg #= "</defs>" # "\n";
        };

        // Begins a group, with the specified style.
        public func groupStyle(t : Text) {
            svg #= Util.group("style", t) # "\n";
        };

        // Begins a group, with the specified transform.
        public func groupTransform(t : Text) {
            svg #= Util.group("transform", t) # "\n";
        };

        // Ends a group.
        public func groupEnd() {
            svg #= "</g>\n";
        };

        // Defines an element with a specified type.
        // - (link): Link reference.
        // - (data): CDATA
        // - Just a closing element.
        private func embed(tag : Text, scriptType : Text, data : [Text]) : Text {
            var e = "<" # tag # " type=\"" # scriptType # "\"";
            if (data.size() == 1 and isLink(data[0])) {
                e #= " " # Util.href(data[0]) # "/>\n";
            } else if (0 < data.size()) {
                e #= ">\n<![CDATA[\n";
                for (v in data.vals()) {
                    e #= v # "\n";
                };
                e #= "]]>\n</" # tag # ">\n";
            } else {
                e #= "/>"
            };
            e;
        };

        public func image(x : Int, y : Int, w : Int, h : Int, link : Text, s : [Text]) {
            svg #= "<image " # Util.dim(x, y, w, h) # " " # Util.href(link) # " " # endStyle(s, emptyClose);
        };

        // Checks whether l is a script reference.
        private func isLink(l : Text) : Bool {
            Text.startsWith(l, #text("http://")) or Text.startsWith(l, #char('#')) or
            Text.startsWith(l, #text("../")) or Text.startsWith(l, #text("./"));
        };

        // Generates end styles based on the given tag and styles.
        private func endStyle(ts : [Text], tag : Text) : Text {
            if (ts.size() == 0) return tag;
            var e = "";
            for (i in ts.keys()) {
                let t = ts[i];
                switch (indexEquals(t)) {
                    case (null) { e #= styleAttr(t); };
                    case (? i) {
                        if (0 < i) { e #= t;  }
                        else { e #= styleAttr(t); };
                    };
                };
                if (i != (ts.size()-1 : Nat)) e #= " ";
            };
            e # tag;
        };

        // Returns a style attribute string.
        private func styleAttr(s : Text) : Text {
            if (s.size() == 0) return s;
            "style=\"" # s # "\"";
        };

        // Return the position of the first equals sign in the given string.
        private func indexEquals(t : Text) : ?Nat {
            var i = 0;
            for (c in Text.toIter(t)) {
                if (c == '=') return ?i;
                i += 1;
            };
            null;
        };

        private module Util {
            // Returns a coordinate string.
            public func coordinate(x : Int, y : Int) : Text {
                Int.toText(x) # "," # Int.toText(y);
            };

            // Returns a dimension string.
            public func dim(x : Int, y : Int, w : Int, h : Int) : Text {
                "x=\"" # Int.toText(x) # "\" y=\"" # Int.toText(y) # "\" width=\"" # Int.toText(w) # "\" height=\"" # Int.toText(h) # "\"";
            };

            // Returns a group element.
            public func group(tag : Text, v : Text) : Text {
                "<g " # tag # "=\"" # v # "\">" 
            };

            // Returns the href name and attribute.
            public func href(l : Text) : Text {
                "xlink:href=\"" # l # "\"";
            };

            // Returns the x and y coordinate attributes.
            public func location(x : Int, y : Int) : Text {
                "x=\"" # Int.toText(x) # "\" y=\"" # Int.toText(y) # "\"";
            };
        };

        public module Transforms {
            // Returns the rotate string for the transform.
            public func rotate(f : Float) : Text {
                "rotate(" # Float.toText(f) # ")";
            };

            // Return the scale string for the transform.
            public func scale(f : Float) : Text {
                "scale(" # Float.toText(f) # ")";
            };

            // Returns the translate string for the transform.
            public func translate(x : Float, y : Float) : Text {
                "translate(" # Float.toText(x) # "," # Float.toText(x) # ")";
            };
        };
    };
};
