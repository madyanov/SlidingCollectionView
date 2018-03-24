## Preview

![Preview](preview.gif)

## Properties

    var itemHeight: CGFloat
    var spacing: CGFloat
    var maximumNumberOfRows: Int

## Delegate

    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, widthForItemAt index: Int) -> CGFloat

    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, didSelectItemAt index: Int)


## DataSource

    func numberOfItems(in slidingCollectionView: SlidingCollectionView) -> Int

    func slidingCollectionView(_ slidingCollectionView: SlidingCollectionView, cellForItemAt index: Int) -> UICollectionViewCell

## Todo

- [ ] Move to Carthage & Cocoapods
- [ ] Support horizontal scrolling axis
