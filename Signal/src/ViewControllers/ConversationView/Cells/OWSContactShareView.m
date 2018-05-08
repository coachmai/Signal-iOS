//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSContactShareView.h"
#import "OWSContactAvatarBuilder.h"
#import "Signal-Swift.h"
#import "UIColor+JSQMessages.h"
#import "UIColor+OWS.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/SignalMessaging-Swift.h>
#import <SignalServiceKit/OWSContact.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSContactShareView ()

@property (nonatomic) ContactShareViewModel *contactShare;
@property (nonatomic, weak) id<OWSContactShareViewDelegate> delegate;

@property (nonatomic) BOOL isIncoming;
@property (nonatomic) OWSContactsManager *contactsManager;

@property (nonatomic, nullable) UIView *buttonView;

@end

#pragma mark -

@implementation OWSContactShareView

- (instancetype)initWithContactShare:(ContactShareViewModel *)contactShare
                          isIncoming:(BOOL)isIncoming
                            delegate:(id<OWSContactShareViewDelegate>)delegate
{
    self = [super init];

    if (self) {
        self.delegate = delegate;
        self.contactShare = contactShare;
        self.isIncoming = isIncoming;
        self.contactsManager = [Environment current].contactsManager;
    }

    return self;
}

- (OWSContactsManager *)contactsManager
{
    return [Environment current].contactsManager;
}

#pragma mark -

- (CGFloat)iconHMargin
{
    return 12.f;
}

- (CGFloat)iconHSpacing
{
    return 8.f;
}

+ (CGFloat)iconVMargin
{
    return 12.f;
}

- (CGFloat)iconVMargin
{
    return [OWSContactShareView iconVMargin];
}

+ (BOOL)hasSendTextButton:(ContactShareViewModel *)contactShare contactsManager:(OWSContactsManager *)contactsManager
{
    OWSAssert(contactShare);
    OWSAssert(contactsManager);

    return [contactShare systemContactsWithSignalAccountPhoneNumbers:contactsManager].count > 0;
}

+ (BOOL)hasInviteButton:(ContactShareViewModel *)contactShare contactsManager:(OWSContactsManager *)contactsManager
{
    OWSAssert(contactShare);
    OWSAssert(contactsManager);

    return [contactShare systemContactPhoneNumbers:contactsManager].count > 0;
}

+ (BOOL)hasAddToContactsButton:(ContactShareViewModel *)contactShare
{
    OWSAssert(contactShare);

    return [contactShare e164PhoneNumbers].count > 0;
}


+ (BOOL)hasAnyButton:(ContactShareViewModel *)contactShare contactsManager:(OWSContactsManager *)contactsManager
{
    OWSAssert(contactShare);

    return ([self hasSendTextButton:contactShare contactsManager:contactsManager] ||
        [self hasInviteButton:contactShare contactsManager:contactsManager] ||
        [self hasAddToContactsButton:contactShare]);
}

+ (CGFloat)bubbleHeightForContactShare:(ContactShareViewModel *)contactShare
{
    OWSAssert(contactShare);

    OWSContactsManager *contactsManager = [Environment current].contactsManager;

    if ([self hasAnyButton:contactShare contactsManager:contactsManager]) {
        return self.contentHeight + self.buttonHeight;
    } else {
        return self.contentHeight;
    }
}

+ (CGFloat)contentHeight
{
    return self.iconSize + self.iconVMargin * 2;
}

+ (CGFloat)buttonHeight
{
    return 44.f;
}

+ (CGFloat)iconSize
{
    return 44.f;
}

- (CGFloat)iconSize
{
    return [OWSContactShareView iconSize];
}

- (CGFloat)vMargin
{
    return 10.f;
}

- (UIColor *)bubbleBackgroundColor
{
    return self.isIncoming ? [UIColor jsq_messageBubbleLightGrayColor] : [UIColor ows_materialBlueColor];
}

- (void)createContents
{
    self.backgroundColor = [UIColor colorWithRGBHex:0xefeff4];
    self.layoutMargins = UIEdgeInsetsZero;

    // TODO: Verify that this layout works in RTL.
    const CGFloat kBubbleTailWidth = 6.f;

    UIView *contentView = [UIView containerView];
    [self addSubview:contentView];
    [contentView autoPinLeadingToSuperviewMarginWithInset:self.isIncoming ? kBubbleTailWidth : 0.f];
    [contentView autoPinTrailingToSuperviewMarginWithInset:self.isIncoming ? 0.f : kBubbleTailWidth];
    [contentView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.vMargin];

    AvatarImageView *avatarView = [AvatarImageView new];
    avatarView.image =
        [self.contactShare getAvatarImageWithDiameter:self.iconSize contactsManager:self.contactsManager];

    [avatarView autoSetDimension:ALDimensionWidth toSize:self.iconSize];
    [avatarView autoSetDimension:ALDimensionHeight toSize:self.iconSize];
    [avatarView setCompressionResistanceHigh];
    [avatarView setContentHuggingHigh];

    UILabel *topLabel = [UILabel new];
    topLabel.text = self.contactShare.displayName;
    topLabel.textColor = [UIColor blackColor];
    topLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    topLabel.font = [UIFont ows_dynamicTypeBodyFont];

    UIStackView *labelsView = [UIStackView new];
    labelsView.axis = UILayoutConstraintAxisVertical;
    labelsView.spacing = 2;
    [labelsView addArrangedSubview:topLabel];

    NSString *_Nullable firstPhoneNumber =
        [self.contactShare systemContactsWithSignalAccountPhoneNumbers:self.contactsManager].firstObject;
    if (firstPhoneNumber.length > 0) {
        UILabel *bottomLabel = [UILabel new];
        bottomLabel.text = [PhoneNumber bestEffortLocalizedPhoneNumberWithE164:firstPhoneNumber];
        bottomLabel.textColor = [UIColor ows_darkGrayColor];
        bottomLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        bottomLabel.font = [UIFont ows_dynamicTypeCaption1Font];
        [labelsView addArrangedSubview:bottomLabel];
    }

    UIImage *disclosureImage =
        [UIImage imageNamed:(self.isRTL ? @"system_disclosure_indicator_rtl" : @"system_disclosure_indicator")];
    OWSAssert(disclosureImage);
    UIImageView *disclosureImageView = [UIImageView new];
    disclosureImageView.image = [disclosureImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    disclosureImageView.tintColor = [UIColor blackColor];
    [disclosureImageView setCompressionResistanceHigh];
    [disclosureImageView setContentHuggingHigh];

    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = self.iconHSpacing;
    stackView.alignment = UIStackViewAlignmentCenter;
    [contentView addSubview:stackView];
    [stackView autoPinLeadingToSuperviewMarginWithInset:self.iconHMargin];
    [stackView autoPinTrailingToSuperviewMarginWithInset:self.iconHMargin];
    [stackView autoVCenterInSuperview];
    // Ensure that the cell's contents never overflow the cell bounds.
    // We pin pin to the superview _edge_ and not _margin_ for the purposes
    // of overflow, so that changes to the margins do not trip these safe guards.
    [stackView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [stackView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];

    [stackView addArrangedSubview:avatarView];
    [stackView addArrangedSubview:labelsView];
    [stackView addArrangedSubview:disclosureImageView];

    if ([OWSContactShareView hasAnyButton:self.contactShare contactsManager:self.contactsManager]) {
        UIStackView *buttonView = [UIStackView new];
        self.buttonView = buttonView;
        buttonView.layoutMargins = UIEdgeInsetsZero;
        [buttonView addBackgroundViewWithBackgroundColor:[UIColor whiteColor]];
        buttonView.axis = UILayoutConstraintAxisHorizontal;
        buttonView.alignment = UIStackViewAlignmentCenter;
        [self addSubview:buttonView];
        [buttonView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:contentView withOffset:self.vMargin];
        [buttonView autoPinWidthToSuperview];
        [buttonView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [buttonView autoSetDimension:ALDimensionHeight toSize:OWSContactShareView.buttonHeight];

        UILabel *label = [UILabel new];
        if ([OWSContactShareView hasSendTextButton:self.contactShare contactsManager:self.contactsManager]) {
            label.text = NSLocalizedString(@"ACTION_SEND_MESSAGE", @"Label for 'sent message' button in contact view.");
        } else if ([OWSContactShareView hasInviteButton:self.contactShare contactsManager:self.contactsManager]) {
            label.text = NSLocalizedString(@"ACTION_INVITE", @"Label for 'invite' button in contact view.");
        } else if ([OWSContactShareView hasAddToContactsButton:self.contactShare]) {
            label.text = NSLocalizedString(@"CONVERSATION_VIEW_ADD_TO_CONTACTS_OFFER",
                @"Message shown in conversation view that offers to add an unknown user to your phone's contacts.");
        } else {
            OWSFail(@"%@ unexpected button state.", self.logTag);
        }
        label.font = [UIFont ows_dynamicTypeBodyFont];
        label.textColor = UIColor.ows_materialBlueColor;
        label.textAlignment = NSTextAlignmentCenter;
        [buttonView addArrangedSubview:label];

        [buttonView logFrameLaterWithLabel:@"buttonView"];
        [label logFrameLaterWithLabel:@"label"];
    } else {
        [contentView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:self.vMargin];
    }
}

- (BOOL)handleTapGesture:(UITapGestureRecognizer *)sender
{
    if (!self.buttonView) {
        return NO;
    }
    CGPoint location = [sender locationInView:self.buttonView];
    if (!CGRectContainsPoint(self.buttonView.bounds, location)) {
        return NO;
    }

    if ([OWSContactShareView hasSendTextButton:self.contactShare contactsManager:self.contactsManager]) {
        [self.delegate sendMessageToContactShare:self.contactShare];
    } else if ([OWSContactShareView hasInviteButton:self.contactShare contactsManager:self.contactsManager]) {
        [self.delegate sendInviteToContactShare:self.contactShare];
    } else if ([OWSContactShareView hasAddToContactsButton:self.contactShare]) {
        [self.delegate showAddToContactUIForContactShare:self.contactShare];
    } else {
        OWSFail(@"%@ unexpected button tap.", self.logTag);
    }

    return YES;
}

@end

NS_ASSUME_NONNULL_END
