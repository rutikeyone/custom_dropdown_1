part of 'custom_dropdown.dart';

const _overlayOuterPadding = EdgeInsets.only(bottom: 12, left: 12, right: 12);
const _overlayShadowOffset = Offset(0, 6);
const _listItemPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);

class _DropdownOverlay extends StatefulWidget {
  final List<String> items;
  final TextEditingController controller;
  final Size size;
  final LayerLink layerLink;
  final VoidCallback hideOverlay;
  final String hintText;
  final TextStyle? headerStyle;
  final TextStyle? listItemStyle;
  final bool? excludeSelected;
  final bool? canCloseOutsideBounds;
  final ValueChanged<int>? onChangedIndex;
  final GlobalKey stickyKey;
  final Decoration? decoration;

  const _DropdownOverlay({
    Key? key,
    required this.items,
    required this.controller,
    required this.size,
    required this.layerLink,
    required this.hideOverlay,
    required this.hintText,
    required this.stickyKey,
    this.headerStyle,
    this.listItemStyle,
    this.excludeSelected,
    this.canCloseOutsideBounds,
    this.onChangedIndex,
    this.decoration,
  }) : super(key: key);

  @override
  _DropdownOverlayState createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay> {
  bool displayOverly = true;
  bool displayOverlayBottom = true;
  late String headerText;
  late List<String> items;
  late List<String> filteredItems;
  final key1 = GlobalKey(), key2 = GlobalKey();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final render1 = key1.currentContext?.findRenderObject() as RenderBox;
      final render2 = key2.currentContext?.findRenderObject() as RenderBox;
      final screenHeight = MediaQuery.of(context).size.height;
      double y = render1.localToGlobal(Offset.zero).dy;
      if (screenHeight - y < render2.size.height) {
        displayOverlayBottom = false;
        setState(() {});
      }
    });

    headerText = widget.controller.text;
    if (widget.excludeSelected! &&
        widget.items.length > 1 &&
        widget.controller.text.isNotEmpty) {
      items = widget.items.where((item) => item != headerText).toList();
    } else {
      items = widget.items;
    }
    filteredItems = items;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final double topPadding;
    final keyContext = widget.stickyKey.currentContext;
    if (keyContext != null) {
      final renderBox = keyContext.findRenderObject() as RenderBox;
      topPadding = renderBox.size.height + 6;
    }
    final borderRadius = BorderRadius.circular(12);
    final overlayOffset = Offset(-12, topPadding);
    const listPadding = EdgeInsets.zero;
    final list = items.isNotEmpty
        ? _ItemsList(
            scrollController: scrollController,
            excludeSelected:
                widget.items.length > 1 ? widget.excludeSelected! : false,
            items: items,
            padding: listPadding,
            headerText: headerText,
            itemTextStyle: widget.listItemStyle,
            onItemSelect: (value) {
              if (headerText != items[value]) {
                widget.controller.text = items[value];
                if (widget.onChangedIndex != null) {
                  widget.onChangedIndex!(value);
                }
              }
              setState(() => displayOverly = false);
            },
          )
        : const SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'Данные для выбора отсутствуют',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );

    final child = Stack(
      children: [
        Positioned(
          width: widget.size.width + 24,
          child: CompositedTransformFollower(
            link: widget.layerLink,
            followerAnchor:
                displayOverlayBottom ? Alignment.topLeft : Alignment.bottomLeft,
            showWhenUnlinked: false,
            offset: overlayOffset,
            child: Container(
              key: key1,
              padding: _overlayOuterPadding,
              child: DecoratedBox(
                decoration: widget.decoration ??
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius: borderRadius,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 24.0,
                          color: Colors.black.withOpacity(.08),
                          offset: _overlayShadowOffset,
                        ),
                      ],
                    ),
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedSection(
                    animationDismissed: widget.hideOverlay,
                    expand: displayOverly,
                    axisAlignment: displayOverlayBottom ? 1.0 : -1.0,
                    child: SizedBox(
                      key: key2,
                      height: items.length > 4 ? 216 : null,
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: NotificationListener<
                            OverscrollIndicatorNotification>(
                          onNotification: (notification) {
                            notification.disallowIndicator();
                            return true;
                          },
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              scrollbarTheme: ScrollbarThemeData(
                                thumbVisibility: MaterialStateProperty.all(
                                  true,
                                ),
                                thickness: MaterialStateProperty.all(5),
                                radius: const Radius.circular(4),
                                thumbColor: MaterialStateProperty.all(
                                  Colors.grey[300],
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                items.length > 4 ? Expanded(child: list) : list
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => setState(() => displayOverly = false),
      child: widget.canCloseOutsideBounds!
          ? Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.transparent,
              child: child,
            )
          : child,
    );
  }
}

class _ItemsList extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> items;
  final bool excludeSelected;
  final String headerText;
  final ValueSetter<int> onItemSelect;
  final EdgeInsets padding;
  final TextStyle? itemTextStyle;

  const _ItemsList({
    Key? key,
    required this.scrollController,
    required this.items,
    required this.excludeSelected,
    required this.headerText,
    required this.onItemSelect,
    required this.padding,
    this.itemTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listItemStyle = const TextStyle(
      fontSize: 16,
    ).merge(itemTextStyle);

    return Scrollbar(
      controller: scrollController,
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        padding: padding,
        itemCount: items.length,
        itemBuilder: (_, index) {
          final selected = !excludeSelected && headerText == items[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.grey[200],
              onTap: () => onItemSelect(index),
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    color: Colors.transparent,
                    padding: _listItemPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            items[index],
                            style: listItemStyle,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        selected
                            ? const Icon(Icons.add, size: 32)
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: const Divider(height: 1, thickness: 1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
