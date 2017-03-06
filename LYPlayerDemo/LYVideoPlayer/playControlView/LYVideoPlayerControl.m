//
//  LYVideoPlayerControl.m
//  LYPlayerDemo
//
//  Created by liyang on 16/11/5.
//  Copyright © 2016年 com.liyang.player. All rights reserved.
//


#import "LYVideoPlayerControl.h"
#define TopHeight    40
#define BottomHeight 40

#define PlayButotn_playImage @"video_play"
#define PlayButotn_pasueImage @"video_pause"

@interface LYVideoPlayerControl () <UIGestureRecognizerDelegate>

//全屏
@property (nonatomic, strong) UIView *fullScreenView;                  //全屏的一个视图
@property (nonatomic, strong) UILabel *fastTimeLabel;                  //全屏显示快进快退时的时间进度
@property (nonatomic, strong) UIActivityIndicatorView *activityView;  //菊花
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;     //滑动手势
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;     //单击手势

//顶部背景视图
@property (nonatomic, strong) UIView   *topView;
@property (nonatomic, strong) UIButton *backButton;      //返回
@property (nonatomic, strong) UIButton *fullScreenButton;//全屏按钮

//底部背景视图
@property (nonatomic, strong) UIView   *bottomView;
@property (nonatomic, strong) UIButton *playButton;   //播放/暂停
@property (nonatomic, strong) UILabel  *currentLabel; //当前播放时间
@property (nonatomic, strong) UILabel  *totalLabel;   //视频总时间

@property (nonatomic, strong) LYSlider *videoSlider;  //滑动条

@property (nonatomic, strong) MPVolumeView *volumeView;  //系统音量控件
@property (strong, nonatomic) UISlider* volumeViewSlider;//控制音量


@end

@implementation LYVideoPlayerControl
{
    CGRect _frame;
    BOOL   _isToShowControl;//是否去显示控制界面
    
    BOOL    _sliderIsTouching;//slider是否正在滑动
    CGPoint _startPoint;    //手势滑动的起始点
    CGPoint _lastPoint;     //记录上次滑动的点
    BOOL    _isStartPan;    //记录手势开始滑动
    CGFloat _fastCurrentTime;//记录当前快进快退的时间
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _frame = frame;
        self.layer.masksToBounds = YES;
        [self creatUI];
    }
    return self;
}
- (void)creatUI{
    
    self.volumeView.frame = self.bounds;
    
    //全屏的东西
    self.fullScreenView.frame = self.bounds;
    self.fastTimeLabel.frame = self.bounds;
    self.activityView.frame = self.bounds;
    //手势
    [self.fullScreenView addGestureRecognizer:self.tapGesture];
    [self.fullScreenView addGestureRecognizer:self.panGesture];
    
    //顶部
    self.topView.frame = CGRectMake(0, 0, _frame.size.width, TopHeight);
    self.backButton.frame = CGRectMake(0, 0, 40, TopHeight);
    self.fullScreenButton.frame = CGRectMake(_frame.size.width - 40, 0, 40, TopHeight);
    
    //低部
    self.bottomView.frame = CGRectMake(0, _frame.size.height - BottomHeight, _frame.size.width, BottomHeight);
    self.playButton.frame = CGRectMake(0, 0, 40, BottomHeight);
    self.currentLabel.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame), 0, 50, BottomHeight);
    self.totalLabel.frame = CGRectMake(_frame.size.width - 50 - 10, 0, 50, BottomHeight);
    
    self.videoSlider.frame = CGRectMake(CGRectGetMaxX(self.currentLabel.frame) + 5, 0, _frame.size.width - CGRectGetMaxX(self.currentLabel.frame) - self.totalLabel.frame.size.width - 20 , BottomHeight);
}

#pragma mark - set get
//全屏
- (UIView *)fullScreenView{
    if (!_fullScreenView) {
        _fullScreenView = [[UIView alloc] init];
        [self addSubview:_fullScreenView];
    }
    return _fullScreenView;
}
- (UILabel *)fastTimeLabel{
    if (!_fastTimeLabel) {
        _fastTimeLabel = [[UILabel alloc] init];
        _fastTimeLabel.textColor = [UIColor whiteColor];
        _fastTimeLabel.font = [UIFont systemFontOfSize:30];
        _fastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _fastTimeLabel.hidden = YES;
        [self.fullScreenView addSubview:_fastTimeLabel];
    }
    return _fastTimeLabel;
}
- (UIActivityIndicatorView *)activityView{
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityView.hidesWhenStopped = YES;
        [self.fullScreenView addSubview:_activityView];
        [_activityView startAnimating];
    }
    return _activityView;
}
- (UITapGestureRecognizer *)tapGesture{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureTouch:)];
        _tapGesture.delegate = self;
    }
    return _tapGesture;
}
- (UIPanGestureRecognizer *)panGesture{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureTouch:)];
    }
    return _panGesture;
}
//顶部
- (UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        [self addSubview:_topView];
    }
    return _topView;
}
- (UIButton *)backButton{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.topView addSubview:_backButton];
    }
    return _backButton;
}
- (UIButton *)fullScreenButton{
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:[UIImage imageNamed:@"normal_screen"] forState:UIControlStateNormal];
        [_fullScreenButton setImage:[UIImage imageNamed:@"full_screen"] forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(fullScreenButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.topView addSubview:_fullScreenButton];
    }
    return _fullScreenButton;
}
//底部背景视图
- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        [self addSubview:_bottomView];
    }
    return _bottomView;
}
- (UIButton *)playButton{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[UIImage imageNamed:PlayButotn_pasueImage] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage imageNamed:PlayButotn_playImage] forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:_playButton];
    }
    return _playButton;
}
- (UILabel *)currentLabel{
    if (!_currentLabel) {
        _currentLabel = [[UILabel alloc] init];
        _currentLabel.text = @"00:00";
        _currentLabel.textColor = [UIColor whiteColor];
        _currentLabel.textAlignment = NSTextAlignmentCenter;
        _currentLabel.font = [UIFont systemFontOfSize:14];
        [self.bottomView addSubview:_currentLabel];
    }
    return _currentLabel;
}
- (UILabel *)totalLabel{
    if (!_totalLabel) {
        _totalLabel = [[UILabel alloc] init];
        _totalLabel.text = @"00:00";
        _totalLabel.textColor = [UIColor whiteColor];
        _totalLabel.textAlignment = NSTextAlignmentCenter;
        _totalLabel.font = [UIFont systemFontOfSize:14];
        [self.bottomView addSubview:_totalLabel];
    }
    return _totalLabel;
}

- (LYSlider *)videoSlider{
    if (!_videoSlider) {
        _videoSlider = [[LYSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.currentLabel.frame) + 5, 0, _frame.size.width - CGRectGetMaxX(self.currentLabel.frame) - self.totalLabel.frame.size.width - 20 , BottomHeight)];
        
        //设置滑块图片样式
        // 1 通过颜色创建 Image
         UIImage *normalImage = [UIImage createImageWithColor:[UIColor redColor] radius:5.0];
        
//        UIView *normalImageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
//        normalImageView.layer.cornerRadius = 1;
//        normalImageView.layer.masksToBounds = YES;
//        normalImageView.backgroundColor = [UIColor whiteColor];
//        UIImage *normalImage = [UIImage creatImageWithView:normalImageView];
        
        // 2 通过view 创建 Image
        UIView *highlightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        highlightView.layer.cornerRadius = 6;
        highlightView.layer.masksToBounds = YES;
        highlightView.backgroundColor = [UIColor redColor];
        UIImage *highlightImage = [UIImage creatImageWithView:highlightView];

        [_videoSlider setThumbImage:normalImage forState:UIControlStateNormal];
        [_videoSlider setThumbImage:highlightImage forState:UIControlStateHighlighted];
        
        _videoSlider.trackHeight = 1.5;
        _videoSlider.thumbVisibleSize = 12;//设置滑块（可见的）大小
        
        [_videoSlider addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];//正在拖动
        [_videoSlider addTarget:self action:@selector(sliderTouchEnd:) forControlEvents:UIControlEventEditingDidEnd];//拖动结束
        [self.bottomView addSubview:_videoSlider];
    }
    return _videoSlider;
}
- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _volumeView;
}

- (void)setTotalTime:(CGFloat)totalTime{
    _totalTime = totalTime;
    self.totalLabel.text = [self timeFormatted:(int)totalTime];
}
- (void)setCurrentTime:(CGFloat)currentTime{
    _currentTime = currentTime;
    if (_sliderIsTouching == NO) {
        self.currentLabel.text = [self timeFormatted:(int)currentTime];
    }
}
- (void)setPlayValue:(CGFloat)playValue{
    _playValue = playValue;
    if (_sliderIsTouching == NO) {
        self.videoSlider.value = playValue;
    }
}
- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    self.videoSlider.bufferProgress = progress;
}

#pragma mark - Event
- (void)sliderValueChange:(LYSlider *)slider{
    _sliderIsTouching = YES;
    self.currentLabel.text = [self timeFormatted:slider.value * self.totalTime];
}
- (void)sliderTouchEnd:(LYSlider *)slider{
    
    if (self.sliderTouchEnd_block) {
        self.sliderTouchEnd_block(slider.value * self.totalTime);
    }
    _sliderIsTouching = NO;
}
- (void)playButtonClick:(UIButton *)sender{
    sender.selected = !sender.selected;
    
    if (self.playButtonClick_block) {
        self.playButtonClick_block(!sender.selected);
    }
}
- (void)backButtonClick:(UIButton *)sender{
    if (self.backButtonClick_block) {
        self.backButtonClick_block();
    }
}
- (void)fullScreenButtonClick:(UIButton *)sender{
    if (self.fullScreenButtonClick_block) {
        self.fullScreenButtonClick_block();
    }
}
- (void)tapGestureTouch:(UITapGestureRecognizer *)tapGesture{
    if (_isToShowControl) {
        self.panGesture.enabled = YES;
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            //            self.topView.alpha = 1;
            //            self.bottomView.alpha = 1;
            self.topView.frame = CGRectMake(0, 0, _frame.size.width, TopHeight);
            self.bottomView.frame = CGRectMake(0, _frame.size.height - BottomHeight, _frame.size.width, BottomHeight);
        } completion:^(BOOL finished) {
            
        }];
    }else{
        self.panGesture.enabled = NO;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            //            self.topView.alpha = 0;
            //            self.bottomView.alpha = 0;
            self.topView.frame = CGRectMake(0, - TopHeight, _frame.size.width, TopHeight);
            self.bottomView.frame = CGRectMake(0, _frame.size.height, _frame.size.width, BottomHeight);
        } completion:^(BOOL finished) {
            
        }];
    }
    _isToShowControl = !_isToShowControl;
}
- (void)panGestureTouch:(UIPanGestureRecognizer *)panGestureTouch{
    CGPoint touPoint = [panGestureTouch translationInView:self];
    static int changeXorY = 0;    //0:X:进度   1:Y：音量
    
    if (panGestureTouch.state == UIGestureRecognizerStateBegan) {
        _startPoint = touPoint;
        _lastPoint = touPoint;
        _isStartPan = YES;
        _fastCurrentTime = self.currentTime;
        changeXorY = 0;
    }else if (panGestureTouch.state == UIGestureRecognizerStateChanged){
        CGFloat change_X = touPoint.x - _startPoint.x;
        CGFloat change_Y = touPoint.y - _startPoint.y;
        
        if (_isStartPan) {
            
            if (fabs(change_X) > fabs(change_Y)) {
                changeXorY = 0;
            }else{
                changeXorY = 1;
            }
            _isStartPan = NO;
        }
        if (changeXorY == 0) {//进度
            self.fastTimeLabel.hidden = NO;
            
            if (touPoint.x - _lastPoint.x >= 1) {
                _lastPoint = touPoint;
                _fastCurrentTime += 2;
                if (_fastCurrentTime > self.totalTime) {
                    _fastCurrentTime = self.totalTime;
                }
            }
            if (touPoint.x - _lastPoint.x <= - 1) {
                _lastPoint = touPoint;
                _fastCurrentTime -= 2;
                if (_fastCurrentTime < 0) {
                    _fastCurrentTime = 0;
                }
            }
            
            NSString *currentTimeString = [self timeFormatted:(int)_fastCurrentTime];
            NSString *totalTimeString = [self timeFormatted:(int)self.totalTime];
            self.fastTimeLabel.text = [NSString stringWithFormat:@"%@/%@",currentTimeString,totalTimeString];
            
        }else{//音量
            if (touPoint.y - _lastPoint.y >= 5) {
                _lastPoint = touPoint;
                self.volumeViewSlider.value -= 0.07;
            }
            if (touPoint.y - _lastPoint.y <= - 5) {
                _lastPoint = touPoint;
                self.volumeViewSlider.value += 0.07;
            }
        }
        
    }else if (panGestureTouch.state == UIGestureRecognizerStateEnded){
        self.fastTimeLabel.hidden = YES;
        if (changeXorY == 0) {
            if (self.fastFastForwardAndRewind_block) {
                self.fastFastForwardAndRewind_block(_fastCurrentTime);
            }
        }
    }
}

#pragma mark - Custom Methods
//横竖屏转换
- (void)fullScreenChanged:(BOOL)isFullScreen{
    _frame = self.bounds;
    [self creatUI];
    
    self.fullScreenButton.selected = isFullScreen;
    
    [self.videoSlider fullScreenChanged:isFullScreen];
}
- (void)videoPlayerDidLoading{
    [self.activityView startAnimating];
//    NSLog(@"正在加载");
}
- (void)videoPlayerDidBeginPlay{
    [self.activityView stopAnimating];
//    NSLog(@"播放开始");
}
- (void)videoPlayerDidEndPlay{
//    NSLog(@"播放结束");
}
- (void)videoPlayerDidFailedPlay{
//    NSLog(@"播放失败");
}

- (void)playerControlPlay{
    self.playButton.selected = NO;
}
- (void)playerControlPause{
    self.playButton.selected = YES;
}
//转换时间格式
- (NSString *)timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d",minutes, seconds];
}

#pragma mark - UIGestureRecognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    if ([touch.view isDescendantOfView:self.fullScreenView]) {
        return YES;
    }
    return NO;
}

@end
