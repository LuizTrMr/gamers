/*
	Name of the package is "dll" to make it simpler when importing.
*/
package dll

// Should be included in your struct with ```using node: Node(Ptr)```
Node :: struct($Ptr: typeid) {
	first, next, prev, last, parent: Ptr,
}

push_first :: proc(parent, child: $Ptr) {
	parent.first = child
	parent.last  = child
	child.parent = parent
}

push_last :: proc(last, next: $Ptr) {
	last.next = next
	next.prev = last
	next.parent = last.parent
	last.parent.last = next
}

node_assign :: proc(node: ^Node($Ptr), value: Ptr) {
	node.first = value
	node.next = value
	node.prev = value
	node.last = value
	node.parent = value
}
