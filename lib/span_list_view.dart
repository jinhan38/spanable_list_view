import 'package:flutter/material.dart';

typedef IndexedWidgetBuilder = Widget Function(int index);

class SpanListView extends StatefulWidget {
  const SpanListView({
    required this.itemCount,
    required this.span,
    required this.usePercentFetchData,
    required this.widgetBuilder,
    this.initStateFunction,
    this.separatorWidget,
    this.horizontalSeparatorWidget,
    this.fetchDataPercent = 0.8,
    this.fetchData,
    this.physics = const ScrollPhysics(),
    this.pinnedHeader,
    this.pinnedFooter,
    this.scrollHeader,
    this.scrollFooter,
    this.shrinkWrap = true,
    this.primary = false,
    this.padding = const EdgeInsets.all(12),
    this.lineVerticalAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.lineItemExpanded = true,
    Key? key,
  })
      : assert((span > 0 && span < 11),
  'span must be less than 11 and higher than 0. Current span is $span.'),
        assert((fetchDataPercent < 1.0 && fetchDataPercent > 0),
        'etchDataPercent must be less than 1.0 and higher than 0. Current fetchDataPercent is $fetchDataPercent'),
        super(key: key);

  ///If [initStateFunction] is not null, it will be called in the initState.
  final Function? initStateFunction;

  ///[itemCount] is the total count of ListView.
  final int itemCount;

  ///[span] decides how many widgets to put in one horizontal line
  ///If set to 3, Three widgets will be rendered per line.
  ///min 1, max 10
  final int span;

  ///[widgetBuilder] is a function than returns a widget.
  ///You can get current index by calling [widgetBuilder],
  ///and rendering each item widget in the ListView
  final IndexedWidgetBuilder widgetBuilder;

  ///you can add Data by calling [fetchData].
  ///When to call can be set to the values of [usePercentFetchData] and [fetchDataPercent].
  final Function? fetchData;

  ///[usePercentFetchData] decides whether to use fetchDataPercent.
  ///If usePercentFetchData is True, you will applies fetchDataPercent.
  ///Otherwise, you will call [fetchData] when the index of ListView reaches last index.
  final bool usePercentFetchData;

  ///[fetchDataPercent] is very important.
  ///fetchDataPercent determines where the data will be called additionally.
  ///If fetchDataPercent is 0.8, you will call fetchData fetchData when itemCount reaches 80 percent.
  ///For example, If itemCount is 100, you will call fetchData when index is 80.
  ///This only applies when [usePercentFetchData] is true.
  ///must be higher than 0 and less than 1
  final double fetchDataPercent;

  ///[physics] is ScrollPhysics of ListView.
  final ScrollPhysics physics;

  ///[scrollHeader] is header of ListView.
  ///Visible when the scroll reaches the top
  final Widget? scrollHeader;

  ///[scrollFooter] is footer of ListView.
  ///Visible when the scroll reaches the bottom
  final Widget? scrollFooter;

  ///[pinnedHeader] is header of ListView.
  ///It is pinned at the top regardless of the scrolling of ListView
  final Widget? pinnedHeader;

  ///[pinnedFooter] is footer of ListView.
  ///It is pinned at the bottom regardless of the scrolling of ListView
  final Widget? pinnedFooter;

  ///[separatorWidget] is separator between vertical lines.
  ///If it is null, It is not added.
  final Widget? separatorWidget;

  ///[horizontalSeparatorWidget] is SeparatorWidget of between items of line Row Widget.
  ///If it is null, It is not added.
  final Widget? horizontalSeparatorWidget;

  ///It is shrinkWrap of ListView.
  final bool shrinkWrap;

  ///It is primary of ListView.
  final bool primary;

  ///It is padding of ListView.
  final EdgeInsets padding;

  ///[lineVerticalAxisAlignment] is CrossAxisAlignment of line Row Widget.
  ///Default is CrossAxisAlignment.center.
  final CrossAxisAlignment lineVerticalAxisAlignment;

  ///[mainAxisAlignment] is MainAxisAlignment of line Row Widget.
  ///Default is MainAxisAlignment.spaceEvenly.
  final MainAxisAlignment mainAxisAlignment;

  ///Default of [lineItemExpanded] is true.
  ///If it is true,parent of items inside line Row Widget is Expanded Widget.
  ///Otherwise, parent of items is Flexible and flex is one.
  final bool lineItemExpanded;

  @override
  _SpanListViewState createState() => _SpanListViewState();
}

class _SpanListViewState extends State<SpanListView> {


  @override
  void initState() {
    if (widget.initStateFunction != null) {
      widget.initStateFunction!();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// When pinnedHeader or pinnedFooter is not null,
    /// after wrapping ListView with Column, put pinnedHeader and pinnedFooter at the top and bottom of ListView.
    /// If pinnedHeader and pinnedFooter are both null, return ListView directly.
    if (widget.pinnedHeader != null || widget.pinnedFooter != null) {
      return Column(
        children: [
          if (widget.pinnedHeader != null) ...[widget.pinnedHeader!],
          Expanded(child: _listViewWidget()),
          if (widget.pinnedFooter != null) ...[widget.pinnedFooter!],
        ],
      );
    } else {
      return _listViewWidget();
    }
  }

  ///ListView Widget
  Widget _listViewWidget() {
    int _itemCount =
    _calcItemCount(itemCount: widget.itemCount, span: widget.span);
    return ListView.separated(
      itemCount: _itemCount,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      primary: widget.primary,
      physics: widget.physics,
      itemBuilder: (context, index) {
        _fetchData(
            usePercentFetchData: widget.usePercentFetchData,
            itemCount: _itemCount,
            currentIndex: index,
            fetchDataPercent: widget.fetchDataPercent,
            fetchData: widget.fetchData);

        List<int> itemIndexList = _calcDataListItemIndex(
            currentIndex: index,
            span: widget.span,
            itemCount: widget.itemCount);

        Widget listItemLine = _listItemLine(
            widgetBuilder: (index) => widget.widgetBuilder(index),
            span: widget.span,
            itemIndexList: itemIndexList,
            horizontalSeparatorWidget: widget.horizontalSeparatorWidget,
            lineVerticalAxisAlignment: widget.lineVerticalAxisAlignment,
            mainAxisAlignment: widget.mainAxisAlignment);

        if (index == 0) {
          if (widget.scrollHeader == null) {
            return listItemLine;
          } else {
            return _listItemLineWithHeader(widget.scrollHeader!, listItemLine);
          }
        } else if (index == _itemCount - 1) {
          if (widget.scrollFooter == null) {
            return listItemLine;
          } else {
            return _listItemLineWithFooter(widget.scrollFooter!, listItemLine);
          }
        } else {
          return listItemLine;
        }
      },
      separatorBuilder: (context, index) {
        return widget.separatorWidget ?? const SizedBox();
      },
    );
  }

  ///[_calcItemCount] is a function that finds itemCount of ListView.
  ///If span is one, returns itemCount as is without calculation.
  ///But span is higher one, itemCount must be calculated considering span.
  int _calcItemCount({required int itemCount, required int span}) {
    if (span == 1) {
      return itemCount;
    } else {
      return (itemCount / span).ceil();
    }
  }

  ///데이터리스트의 몇번째 index인지 알아야 함
  ///0이나 1인 경우에는 인덱스 그대로 반환
  ///span이 1보다 큰 경우 현재 리스트의 index와 span을 이용해서
  ///dataList의 index 값을 list에 담아서 반환
  List<int> _calcDataListItemIndex(
      {required int currentIndex, required int span, required int itemCount}) {
    List<int> itemIndexList = [];
    if (span == 1) {
      itemIndexList.add(currentIndex);
    } else {
      ///현재 몇번째 줄인지 체크
      int index = currentIndex * span;

      int count = 0;
      for (int i = 0; i < span; i++) {
        int tempIndex = index + count;
        if (tempIndex < itemCount) itemIndexList.add(tempIndex);
        count++;
      }
    }
    return itemIndexList;
  }

  ///If will be called when [widget.scrollHeader] is not null.
  Widget _listItemLineWithHeader(Widget scrollHeader, Widget listItemLine) {
    return Column(
      children: [
        scrollHeader,
        listItemLine,
      ],
    );
  }

  ///If will be called when [widget.scrollFooter] is not null.
  Widget _listItemLineWithFooter(Widget scrollFooter, Widget listItemLine) {
    return Column(
      children: [
        listItemLine,
        scrollFooter,
      ],
    );
  }

  ///one line Widget
  ///you can set Alignment by using values of [lineVerticalAxisAlignment], [mainAxisAlignment], and [widget.lineItemExpanded].
  ///If horizontalSeparatorWidget is not null, could put separatorWidget.
  Widget _listItemLine({
    required IndexedWidgetBuilder widgetBuilder,
    required int span,
    required List<int> itemIndexList,
    required Widget? horizontalSeparatorWidget,
    required CrossAxisAlignment lineVerticalAxisAlignment,
    required MainAxisAlignment mainAxisAlignment,
  }) {
    return Row(
      crossAxisAlignment: lineVerticalAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (int i = 0; i < itemIndexList.length; i++) ...[
          if (widget.lineItemExpanded) ...[
            Expanded(child: widgetBuilder(itemIndexList[i])),
          ] else
            ...[
              Flexible(flex: 1, child: widgetBuilder(itemIndexList[i])),
            ],
          if (horizontalSeparatorWidget != null &&
              i < itemIndexList.length - 1) ...[horizontalSeparatorWidget],
        ],
      ],
    );
  }

  ///It can be called when [fetchData] is not null.
  ///If [usePercentFetchData] will be True, decides when to call fetchData by using [fetchDataPercent].
  ///Otherwise, It will be called when currentIndex reaches last index.
  Future<void> _fetchData({
    required bool usePercentFetchData,
    required int itemCount,
    required int currentIndex,
    required double fetchDataPercent,
    required Function? fetchData,
  }) async {
    if (fetchData != null) {
      if (usePercentFetchData) {
        if (currentIndex == (itemCount * fetchDataPercent).floor()) {
          await fetchData();
        }
      } else {
        if (currentIndex == itemCount - 1) await fetchData();
      }
    }
  }

}
