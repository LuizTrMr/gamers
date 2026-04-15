/*
	Name of the package is "dll" to make it simpler when importing.
*/
package dll

// Should be included in your struct with ```using node: Node(Ptr)```
Node :: struct($Ptr: typeid) {
	first, next, prev, last, parent: Ptr,
}

/* Untested
push_child :: proc(parent, child: $Ptr) {
	if parent.first != nil {
		last := parent.last
		parent.last.next = child
		child.parent = parent
		child.prev = parent.last
		parent.last = child
	}
	else {
		parent.first = child
		parent.last = child
		child.parent = parent
	}
}
*/

push_next :: proc(sibling, next: $Ptr) {
	assert(sibling.next == nil, "Would need to change this proc or create another one")
	sibling.next = next
	next.prev = sibling
	next.parent = sibling.parent
	sibling.parent.last = next
}
