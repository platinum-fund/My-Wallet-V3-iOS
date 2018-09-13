//
//  ExchangeCreateViewController.swift
//  Blockchain
//
//  Created by kevinwu on 8/15/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

class ExchangeCreateViewController: UIViewController {
    
    // MARK: Private Static Properties
    
    static let primaryFontName: String = Constants.FontNames.montserratRegular
    static let primaryFontSize: CGFloat = Constants.FontSizes.Huge
    static let secondaryFontName: String = Constants.FontNames.montserratRegular
    static let secondaryFontSize: CGFloat = Constants.FontSizes.SmallMedium

    // MARK: - IBOutlets

    @IBOutlet private var tradingPairView: TradingPairView!
    @IBOutlet private var numberKeypadView: NumberKeypadView!

    // Label to be updated when amount is being typed in
    @IBOutlet private var primaryAmountLabel: UILabel!

    // Amount being typed for fiat values to the right of the decimal separator
    @IBOutlet var primaryDecimalLabel: UILabel!
    @IBOutlet var decimalLabelSpacingConstraint: NSLayoutConstraint!

    // Amount being typed in converted to input crypto or input fiat
    @IBOutlet private var secondaryAmountLabel: UILabel!

    @IBOutlet private var useMinimumButton: UIButton!
    @IBOutlet private var useMaximumButton: UIButton!
    @IBOutlet private var exchangeRateView: UIView!
    @IBOutlet private var exchangeRateButton: UIButton!
    @IBOutlet private var exchangeButton: UIButton!
    // MARK: - IBActions

    @IBAction private func displayInputTypeTapped(_ sender: Any) {
        delegate?.onDisplayInputTypeTapped()
    }

    // MARK: Public Properties

    weak var delegate: ExchangeCreateDelegate?

    // MARK: Private Properties

    fileprivate var presenter: ExchangeCreatePresenter!
    fileprivate var dependencies: ExchangeDependencies!

    // MARK: Factory
    
    class func make(with dependencies: ExchangeDependencies) -> ExchangeCreateViewController {
        let controller = ExchangeCreateViewController.makeFromStoryboard()
        controller.dependencies = dependencies
        return controller
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        dependenciesSetup()
        delegate?.onViewLoaded()
        
        
        let demo = Trade.demo()
        let model = TradingPairView.confirmationModel(for: demo)
        tradingPairView.apply(model: model)
        

        primaryAmountLabel.textColor = UIColor.brandPrimary
        secondaryAmountLabel.textColor = UIColor.brandPrimary
        
        useMaximumButton.layer.cornerRadius = 4.0
        useMaximumButton.layer.borderWidth = 1.0
        useMaximumButton.layer.borderColor = UIColor.brandPrimary.cgColor
        
        useMinimumButton.layer.cornerRadius = 4.0
        useMinimumButton.layer.borderWidth = 1.0
        useMinimumButton.layer.borderColor = UIColor.brandPrimary.cgColor
        
        exchangeButton.layer.cornerRadius = 4.0
        exchangeRateView.layer.cornerRadius = 4.0
        exchangeRateView.layer.borderWidth = 1.0
        exchangeRateView.layer.borderColor = UIColor.brandPrimary.cgColor

        primaryAmountLabel.font = UIFont(name: Constants.FontNames.montserratRegular, size: Constants.FontSizes.Huge)
        secondaryAmountLabel.font = UIFont(name: Constants.FontNames.montserratRegular, size: Constants.FontSizes.MediumLarge)
        
        if let navController = navigationController as? BCNavigationController {
            navController.applyLightAppearance()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let navController = navigationController as? BCNavigationController {
            navController.applyDarkAppearance()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    fileprivate func dependenciesSetup() {
        // DEBUG - ideally add an .empty state for a blank/loading state for MarketsModel here.
        let interactor = ExchangeCreateInteractor(
            dependencies: dependencies,
            model: MarketsModel(
                pair: TradingPair(from: .bitcoin, to: .ethereum)!,
                fiatCurrency: "USD",
                fix: .base,
                volume: 0)
        )
        numberKeypadView.delegate = self
        presenter = ExchangeCreatePresenter(interactor: interactor)
        presenter.interface = self
        interactor.output = presenter
        delegate = presenter
    }
}

extension ExchangeCreateViewController: NumberKeypadViewDelegate {
    func onDelimiterTapped(value: String) {
        delegate?.onDelimiterTapped(value: value)
    }
    
    func onAddInputTapped(value: String) {
        delegate?.onAddInputTapped(value: value)
    }

    func onBackspaceTapped() {
        delegate?.onBackspaceTapped()
    }
}

extension ExchangeCreateViewController: ExchangeCreateInterface {
    
    func wigglePrimaryPrimaryLabel() {
        guard primaryAmountLabel.layer.animationKeys() == nil else { return }
        let wiggle = CABasicAnimation(keyPath: "position")
        wiggle.duration = 0.05
        wiggle.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        wiggle.repeatCount = 1
        wiggle.autoreverses = true
        wiggle.fromValue = CGPoint(
            x: primaryAmountLabel.center.x - 2.0,
            y: primaryAmountLabel.center.y
        )
        wiggle.toValue = CGPoint(
            x: primaryAmountLabel.center.x + 2.0,
            y: primaryAmountLabel.center.y
        )
        primaryAmountLabel.layer.add(wiggle, forKey: wiggle.keyPath)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
    
    func styleTemplate() -> ExchangeStyleTemplate {
        
        let primary = UIFont(
            name: ExchangeCreateViewController.primaryFontName,
            size: ExchangeCreateViewController.primaryFontSize
        ) ?? UIFont.systemFont(ofSize: 17.0)
        
        let secondary = UIFont(
            name: ExchangeCreateViewController.secondaryFontName,
            size: ExchangeCreateViewController.secondaryFontSize
            ) ?? UIFont.systemFont(ofSize: 17.0)
        
        return ExchangeStyleTemplate(
            primaryFont: primary,
            secondaryFont: secondary,
            textColor: .brandPrimary,
            pendingColor: UIColor.brandPrimary.withAlphaComponent(0.5)
        )
    }
    
    func primaryFont() -> UIFont {
        guard let font = UIFont(
            name: Constants.FontNames.montserratRegular,
            size: Constants.FontSizes.Gigantic
            ) else {
            return UIFont.systemFont(ofSize: Constants.FontSizes.Gigantic)
        }
        
        return font
    }
    
    func secondaryFont() -> UIFont {
        guard let font = UIFont(
            name: Constants.FontNames.montserratRegular,
            size: Constants.FontSizes.MediumLarge
            ) else {
                return UIFont.systemFont(ofSize: Constants.FontSizes.MediumLarge)
        }
        
        return font
    }
    
    func updateAttributedPrimary(_ primary: NSAttributedString?, secondary: String?) {
        primaryAmountLabel.attributedText = primary
        secondaryAmountLabel.text = secondary
    }
    
    
    func ratesViewVisibility(_ visibility: Visibility) {

    }

    func updateInputLabels(primary: String?, primaryDecimal: String?, secondary: String?) {
        primaryAmountLabel.text = primary
        secondaryAmountLabel.text = secondary
    }

    func updateTradingPairViewValues(left: String, right: String) {
        let transitionUpdate = TradingPairView.TradingTransitionUpdate(
            transitions: [.titles(left: left, right: right)],
            transition: .none
        )
        tradingPairView.apply(transitionUpdate: transitionUpdate)
    }

    func updateRateLabels(first: String, second: String, third: String) {

    }
}
