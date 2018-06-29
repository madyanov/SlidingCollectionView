**iOS 10+**

Paging CollectionView with simple behavior: cells are aligned to the left edge on each page.

## Preview

![Preview](preview.gif)

## Properties

```swift
var itemHeight: CGFloat = 40

var spacing: CGFloat = 8

var maximumNumberOfRows: Int = 4

// height of the collection view to fit enough rows
var heightToFit: CGFloat
```

## Methods

```swift
func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String)

func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell

func reloadData()
```

## Delegate

```swift
func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, widthForItemAt index: Int) -> CGFloat

func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, didSelectItemAt index: Int)
```


## Data Source

```swift
func numberOfItems(in slidingCollectionView: SlidingCollectionView) -> Int

func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, cellForItemAt index: Int) -> UICollectionViewCell
```

## Todo

- [ ] Add to Carthage & Cocoapods
- [ ] Support vertical axis
