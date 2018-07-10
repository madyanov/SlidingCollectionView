**iOS 10+**

Paging CollectionView with simple behavior: cells are aligned to the left edge on each page.

## Preview

![Preview](preview.gif)

## Properties

```swift
// height of the items
var itemHeight: CGFloat { get set }

// horizontal & vertical spacing between items
var spacing: CGFloat { get set }

// maximum number of rows in the collection
var maximumNumberOfRows: Int { get set }

// suggested height of the collection view to fit enough rows
var heightToFit: CGFloat { get }

// indicates whether the user has begun scrolling the content
var isDragging: Bool { get }

// indicates whether the content is moving in the collection view after the user lifted their finger
var isDecelerating: Bool { get }
```

## Methods

```swift
// register cell class
func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String)

// dequeue cell
func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell

// reload data at the end of the run loop
func setNeedsReloadData()

// reload data immediately
func reloadData()
```

## Delegate

```swift
func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, widthForItemAt index: Int) -> CGFloat

func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, didSelectItemAt index: Int)

func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, willDisplay cell: UICollectionViewCell)
```


## Data Source

```swift
func numberOfItems(in slidingCollectionView: SlidingCollectionView) -> Int

func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, cellForItemAt index: Int) -> UICollectionViewCell
```

## Todo

- [ ] Vertical axis support
