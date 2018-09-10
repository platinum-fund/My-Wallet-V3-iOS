//
//  ExchangeCreateInteractor.swift
//  Blockchain
//
//  Created by kevinwu on 8/28/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import RxSwift

class ExchangeCreateInteractor {
    var disposable: Disposable?
    weak var output: ExchangeCreateOutput?
    fileprivate var inputs: ExchangeInputsAPI
    fileprivate var markets: ExchangeMarketsAPI
    fileprivate var conversions: ExchangeConversionAPI
    private var model: MarketsModel? {
        didSet {
            if markets.hasAuthenticated {
                updateMarketsConversion()
            }
        }
    }

    init(dependencies: ExchangeDependencies,
         model: MarketsModel
    ) {
        self.markets = dependencies.markets
        self.inputs = dependencies.inputs
        self.conversions = dependencies.conversions
        self.model = model
    }

    deinit {
        disposable?.dispose()
        disposable = nil
    }
}

extension ExchangeCreateInteractor: ExchangeCreateInput {
    func viewLoaded() {
        markets.setup()

        // Authenticate, then listen for conversions
        markets.authenticate(completion: { [unowned self] in
            self.subscribeToConversions()
            self.updateMarketsConversion()
        })
    }

    func subscribeToConversions() {
        disposable = markets.conversions.subscribe(onNext: { [weak self] conversion in
            guard let this = self else { return }

            // Use conversions service to determine new input/output
            this.conversions.update(with: conversion)
            let input = this.inputs.activeInput.input

            // Remove trailing zeros and decimal place - if the input values are equal, then avoid replacing
            // text, which would interrupt user entry
            let inputTest = this.conversions.removeInsignificantCharacters(input: input)
            let conversionInputTest = this.conversions.removeInsignificantCharacters(input: this.conversions.input)

            if inputTest != conversionInputTest {
                this.inputs.activeInput.input = this.conversions.input
            }

            // Update output
            this.inputs.lastOutput = this.conversions.output

            // Update interface
            this.updateOutput()
        }, onError: { error in
            Logger.shared.error("Error subscribing to quote with trading pair")
        })
    }

    func updateMarketsConversion() {
        guard let model = model else {
            Logger.shared.error("Updating conversion with no model")
            return
        }
        markets.updateConversion(model: model)
    }

    func updatedInput() {
        // Update model volume
        guard let model = model else {
            Logger.shared.error("Updating input with no model")
            return
        }
        model.volume = Decimal(string: inputs.activeInput.input)!

        updateOutput()

        // Re-subscribe to socket with new volume value
        updateMarketsConversion()
    }

    func updateOutput() {
        // Update the inputs in crypto and fiat
        if model?.isUsingFiat == true {
            let components = inputs.inputComponents
            output?.updatedInput(
                primary: components.integer,
                primaryDecimal: components.fractional,
                secondary: inputs.lastOutput
            )
        } else {
            output?.updatedInput(
                primary: inputs.activeInput.input,
                primaryDecimal: nil,
                secondary: inputs.lastOutput
            )
        }

        // TODO: update the amounts shown in the Trading Pair view
    }

    func displayInputTypeTapped() {
        model?.toggleFiatInput()
        inputs.toggleInput()
        updatedInput()
    }
    
    func ratesViewTapped() {
        
    }
    
    func useMinimumAmount() {
        
    }
    
    func useMaximumAmount() {
        
    }
    
    func onBackspaceTapped() {
        inputs.backspace()
        updatedInput()
    }
    
    func onAddInputTapped(value: String) {
        guard let model = model else {
            Logger.shared.error("Updating conversion with no model")
            return
        }
        if model.isUsingFiat == true {
            if let fractional = inputs.inputComponents.fractional,
                fractional.count >= NumberFormatter.localCurrencyFractionDigits {
                Logger.shared.warning("Cannot add more than two decimal values for fiat")
                return
            }
        } else {
            if let fractional = inputs.inputComponents.fractional,
                fractional.count >= NumberFormatter.assetFractionDigits {
                Logger.shared.warning("Cannot add more than eight decimal values for crypto")
                return
            }
        }
        inputs.add(character: value)
        updatedInput()
    }
}
