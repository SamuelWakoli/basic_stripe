const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret); // Access Stripe secret key

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Creates a payment link for a specified product and customer.
 * 
 * @param {Object} data - The data provided by the client.
 * @param {string} data.productId - The ID of the product for which the payment link is to be created.
 * @param {string} [data.customerEmail] - The email of the customer. Used if customerId is not provided.
 * @param {string} [data.customerId] - The ID of the customer. Used if customerEmail is not provided.
 * @param {number} data.quantity - The quantity of the product.
 * 
 * @returns {Object} - Contains the payment link URL and the customer ID.
 * @throws {functions.https.HttpsError} - Throws an error if quantity is invalid, customer cannot be found or created, or price for the product is not found.
 */
exports.createPaymentLink = functions.https.onCall(async (data, context) => {
    try {
        const { productId, customerEmail, customerId, quantity } = data;

        // Validate quantity
        if (!quantity || quantity < 1) {
            throw new functions.https.HttpsError('invalid-argument', 'Quantity must be at least 1.');
        }

        let customer;

        // Check if a customer ID is provided
        if (customerId) {
            customer = await stripe.customers.retrieve(customerId);
        } else if (customerEmail) {
            // Retrieve customer by email or create a new customer if not found
            const customers = await stripe.customers.list({
                email: customerEmail,
                limit: 1,
            });

            if (customers.data.length > 0) {
                customer = customers.data[0];
            } else {
                customer = await stripe.customers.create({
                    email: customerEmail,
                });
            }
        } else {
            throw new functions.https.HttpsError('invalid-argument', 'Customer email or ID must be provided.');
        }

        // Retrieve price for the product
        const prices = await stripe.prices.list({
            product: productId,
            active: true,
            limit: 1,
        });

        if (prices.data.length === 0) {
            throw new functions.https.HttpsError('not-found', 'No price found for the given product ID.');
        }

        const price = prices.data[0];

        // Get current date and time
        const now = new Date();
        const timeStamp = now.toISOString();
        const date = now.toLocaleDateString('en-US');
        const time = now.toLocaleTimeString('en-US');

        // Create a payment link and use metadata to attach customer ID, timestamp, date, and time
        const paymentLink = await stripe.paymentLinks.create({
            line_items: [{
                price: price.id,
                quantity: quantity,
            }],
            metadata: {
                customerId: customer.id, // Attach customer ID via metadata
                time_stamp: timeStamp, // ISO 8601 timestamp
                date: date, // Date in American format
                time: time // Time in American format
            },
        });

        return { url: paymentLink.url, customerId: customer.id };
    } catch (error) {
        console.error('Error creating payment link:', error);
        throw new functions.https.HttpsError('unknown', error.message);
    }
});

/**
 * Creates a checkout session for a specified product and customer.
 *
 * @param {Object} data - The data provided by the client.
 * @param {string} data.productId - The ID of the product for which the checkout session is to be created.
 * @param {string} [data.customerEmail] - The email of the customer. Used if customerId is not provided.
 * @param {string} [data.customerId] - The ID of the customer. Used if customerEmail is not provided.
 * @param {number} data.quantity - The quantity of the product.
 * @param {string} data.successUrl - The URL to redirect to upon successful payment.
 * @param {string} data.cancelUrl - The URL to redirect to if the payment is canceled.
 *
 * @returns {Object} - Contains the checkout session URL and the customer ID.
 * @throws {functions.https.HttpsError} - Throws an error if quantity is invalid, customer cannot be found or created, or price for the product is not found.
 */
exports.createCheckoutSessionViaHTTP = functions.https.onCall(async (data, context) => {
    try {
        const { productId, customerEmail, customerId, quantity, successUrl, cancelUrl } = data;

        // Validate quantity
        if (!quantity || quantity < 1) {
            throw new functions.https.HttpsError('invalid-argument', 'Quantity must be at least 1.');
        }

        let customer;

        // Check if a customer ID is provided
        if (customerId) {
            customer = await stripe.customers.retrieve(customerId);
        } else if (customerEmail) {
            // Retrieve customer by email or create a new customer if not found
            const customers = await stripe.customers.list({
                email: customerEmail,
                limit: 1,
            });

            if (customers.data.length > 0) {
                customer = customers.data[0];
            } else {
                customer = await stripe.customers.create({
                    email: customerEmail,
                });
            }
        } else {
            throw new functions.https.HttpsError('invalid-argument', 'Customer email or ID must be provided.');
        }

        // Retrieve price for the product
        const prices = await stripe.prices.list({
            product: productId,
            active: true,
            limit: 1,
        });

        if (prices.data.length === 0) {
            throw new functions.https.HttpsError('not-found', 'No price found for the given product ID.');
        }

        const price = prices.data[0];

        // Get current date and time
        const now = new Date();
        const timeStamp = now.toISOString();
        const date = now.toLocaleDateString('en-US');
        const time = now.toLocaleTimeString('en-US');

        // Create a checkout session with the customer and the specified quantity
        const session = await stripe.checkout.sessions.create({
            customer: customer.id,
            payment_method_types: ['card'],
            line_items: [{
                price: price.id,
                quantity: quantity,
            }],
            mode: 'payment',
            success_url: successUrl,
            cancel_url: cancelUrl,
            metadata: {
                customerId: customer.id, // Attach customer ID via metadata
                time_stamp: timeStamp, // ISO 8601 timestamp
                date: date, // Date in American format
                time: time // Time in American format
            },
        });

        return { url: session.url, customerId: customer.id };
    } catch (error) {
        console.error('Error creating checkout session:', error);
        throw new functions.https.HttpsError('unknown', error.message);
    }
});
